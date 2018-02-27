import psycopg2
import praw, prawcore
import json
from datetime import datetime
from time import sleep

subreddits = ["ethtrader", "ethereum", "ethdev", "ethermining"]

conn_string = "host='localhost' dbname='reddit' user='postgres' password=''"
conn = psycopg2.connect(conn_string)
cursor = conn.cursor()

reddit = praw.Reddit()

def save_post(data):
    cursor.execute("""
        INSERT INTO posts (reddit_id, author, subreddit, reddit_created_utc, score, ups, downs, is_self, collected)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (reddit_id)
        DO UPDATE SET (score, ups, downs) = (EXCLUDED.score, EXCLUDED.ups, EXCLUDED.downs)
    """, data)

def save_comment(data):
    cursor.execute("""
        INSERT INTO comments (reddit_id, author, subreddit, reddit_created_utc, score, ups, downs, post_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (reddit_id)
        DO UPDATE SET (score, ups, downs) = (EXCLUDED.score, EXCLUDED.ups, EXCLUDED.downs)
    """, data)

def save_user(data):
    cursor.execute("INSERT INTO users (username) VALUES (%s) ON CONFLICT (username) DO NOTHING", data)

def collect_post(post, just_comments=False):
    if just_comments is False and post.author:
        save_user((post.author.name,))
    post.comments.replace_more(limit=None)
    for comment in post.comments.list():
        if comment.author:
            save_user((comment.author.name,))
        save_comment((comment.id, comment.author.name if comment.author is not None else None, str.lower(comment.subreddit.display_name), datetime.fromtimestamp(comment.created_utc), comment.score, comment.ups, comment.downs, comment.submission.id))
    if just_comments is False:
        save_post((post.id, post.author.name if post.author is not None else None, str.lower(post.subreddit.display_name), datetime.fromtimestamp(post.created_utc), post.score, post.ups, post.downs, post.is_self, True))
    else:
        cursor.execute("UPDATE posts SET collected = true WHERE reddit_id = %s", (post.id,))
    conn.commit()
    print("saved: " + post.id)

def collect_user(username, full):
    print("saving: " + username)
    redditor = reddit.redditor(username)
    for post in redditor.submissions.top(limit=None) if full else redditor.submissions.top(time_filter="month", limit=None):
        if post.subreddit in subreddits:
            save_post((post.id, post.author.name if post.author is not None else None, str.lower(post.subreddit.display_name), datetime.fromtimestamp(post.created_utc), post.score, post.ups, post.downs, post.is_self, False))
    for comment in redditor.comments.top(limit=None) if full else redditor.comments.top(time_filter="month", limit=None):
        if comment.subreddit in subreddits:
            save_comment((comment.id, comment.author.name if comment.author is not None else None, str.lower(comment.subreddit.display_name), datetime.fromtimestamp(comment.created_utc), comment.score, comment.ups, comment.downs, comment.submission.id))
    cursor.execute("UPDATE users SET collected = true, joined = %s WHERE username = %s", (datetime.fromtimestamp(redditor.created_utc) if hasattr(redditor, 'created_utc') else None, username))
    conn.commit()

def get_top_posts(subreddit):
    for post in reddit.subreddit(subreddit).top(limit=None):
        collect_post(post)

def get_user_karmas(first):
    if first:
        cursor.execute("SELECT username FROM users WHERE collected = false ORDER BY id ASC")
    else:
        cursor.execute("SELECT username FROM users ORDER BY id ASC")
    users = cursor.fetchall()
    for username in [i[0] for i in users]:
        try:
            collect_user(username, first)
        except Exception as err:
            if hasattr(err, 'response') and (err.response.status_code == 403 or err.response.status_code == 404 or err.response.status_code == 500):
                cursor.execute("UPDATE users SET collected = true WHERE username = %s", (username,))
                conn.commit()
                print("failed " + str(err.response.status_code)+": "+username)
            else:
                print("failed: " + username)
                raise

def get_post_karmas():
    cursor.execute("SELECT reddit_id FROM posts WHERE collected = false")
    posts = cursor.fetchall()
    for post_id in [i[0] for i in posts]:
        try:
            post = reddit.submission(id=post_id)
            collect_post(post, True)
        except Exception as err:
            if err.response.status_code == 403 or err.response.status_code == 404 or err.response.status_code == 500:
                print("failed " + str(err.response.status_code)+": "+post_id)
            else:
                print("failed: " + post_id)
                raise

def get_parent_posts():
    cursor.execute("SELECT DISTINCT(post_id) FROM comments WHERE post_id NOT IN (SELECT reddit_id FROM posts)")
    posts = cursor.fetchall()
    for post_id in [i[0] for i in posts]:
        try:
            post = reddit.submission(id=post_id)
            collect_post(post)
        except Exception as err:
            if err.response.status_code == 403 or err.response.status_code == 404 or err.response.status_code == 500:
                print("failed " + str(err.response.status_code)+": "+post_id)
            else:
                print("failed: " + post_id)
                raise

#for subreddit in subreddits:
#    get_top_posts(subreddit)
count = 0

while True:
    get_user_karmas(count == 0)
    get_post_karmas()
    get_parent_posts()
    print("pausing after fetch: " + count)
    sleep(10*60)
    count += 1

cursor.close()
conn.close()
