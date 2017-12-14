This repo is a collection of scripts and tools for extracting post and comment karma from subreddits. Collecting data from Reddit via their api has limitations. Any "listing" (posts, comments) can only return a  maximum of 1000 items. In order to extract as much karma as possible, the following method has been used:

### Method

1. Get Top Posts.
   * For `r/ethereum` & `r/ethtrader`, retrieve the top posts (~1000 each).
   * Store users and karma from these posts and their comments
   * Mark users as "uncollected".
2. Get User Content.
   * Retrieve posts & comments, filtering `r/ethereum` & `r/ethtrader`, for each "uncollected" user.
   * Mark these users as "collected".
   * Mark *new* (user, comment parent) posts as "uncollected".
3. Get Posts.
   * Retrieve "uncollected" posts
   * Store users and karma from these posts and their comments
   * Mark these posts as "collected".
4. Repeat 2) & 3) until no "uncollected" users or posts.

```
CREATE TABLE user_scores
AS (
  SELECT author as username,
    sum(ethereum_posts_score) as ethereum_posts_score,
    sum(ethtrader_posts_score) as ethtrader_posts_score,
    sum(ethdev_posts_score) as ethdev_posts_score,
    sum(ethermining_posts_score) as ethermining_posts_score,
    sum(ethereum_comments_score) as ethereum_comments_score,
    sum(ethtrader_comments_score) as ethtrader_comments_score,
    sum(ethdev_comments_score) as ethdev_comments_score,
    sum(ethermining_comments_score) as ethermining_comments_score
  FROM content_scores
  WHERE reddit_created_utc::DATE <= '2017-09-30'
  AND author IS NOT NULL
  GROUP BY username
);

ALTER TABLE user_scores ADD PRIMARY KEY (username);
```

```
INSERT INTO user_scores (
  SELECT author as username,
    sum(ethereum_posts_score) as ethereum_posts_score,
    sum(ethtrader_posts_score) as ethtrader_posts_score,
    sum(ethdev_posts_score) as ethdev_posts_score,
    sum(ethermining_posts_score) as ethermining_posts_score,
    sum(ethereum_comments_score) as ethereum_comments_score,
    sum(ethtrader_comments_score) as ethtrader_comments_score,
    sum(ethdev_comments_score) as ethdev_comments_score,
    sum(ethermining_comments_score) as ethermining_comments_score
  FROM content_scores
  WHERE author IS NOT NULL
  GROUP BY username
);
```

```
SELECT sum(score) FROM posts
WHERE score > 0
AND author IS NOT NULL
AND reddit_created_utc::DATE <= '2017-09-30';
```
1837707

```
SELECT sum(score) FROM comments
WHERE score > 0
AND author IS NOT NULL
AND reddit_created_utc::DATE <= '2017-09-30';
```
5807539

total_user_karma = 7645246
mod_endow_ratio = 0.025
total_mod_days ~ 8000 (TBD)
mod_day_rate = mod_endow_ratio * total_user_karma / total_mod_days ~ 24
