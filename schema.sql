CREATE TYPE subreddit AS ENUM ('ethtrader', 'ethereum');
ALTER TYPE subreddit ADD VALUE 'ethdev';
ALTER TYPE subreddit ADD VALUE 'ethermining';

CREATE TABLE IF NOT EXISTS content (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  reddit_id VARCHAR NOT NULL UNIQUE,
  author VARCHAR,
  subreddit subreddit NOT NULL,
  reddit_created_utc TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  score integer NOT NULL,
  ups integer,
  downs integer
);

-- ALTER TABLE content ADD COLUMN ups integer;
-- ALTER TABLE content ADD COLUMN downs integer;

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR NOT NULL UNIQUE,
  collected BOOLEAN DEFAULT false,
  joined TIMESTAMP WITHOUT TIME ZONE
);

-- ALTER TABLE users ADD COLUMN joined TIMESTAMP WITHOUT TIME ZONE;

CREATE TABLE IF NOT EXISTS posts (
  is_self BOOLEAN,
  collected BOOLEAN DEFAULT false
) INHERITS (content);

-- ALTER TABLE posts ADD COLUMN is_self BOOLEAN;

ALTER TABLE posts ADD PRIMARY KEY (id);
ALTER TABLE posts ADD CONSTRAINT unique_reddit_post UNIQUE (reddit_id);
ALTER TABLE posts ADD CONSTRAINT post_author_fk FOREIGN KEY (author) REFERENCES users (username);

CREATE TABLE IF NOT EXISTS comments (
  post_id VARCHAR NOT NULL
) INHERITS (content);

ALTER TABLE comments ADD PRIMARY KEY (id);
ALTER TABLE comments ADD CONSTRAINT unique_reddit_comment UNIQUE (reddit_id);
ALTER TABLE comments ADD CONSTRAINT comment_author_fk FOREIGN KEY (author) REFERENCES users (username);

CREATE INDEX post_created_idx ON posts ( (reddit_created_utc::DATE) );
CREATE INDEX comment_created_idx ON comments ( (reddit_created_utc::DATE) );

CREATE VIEW content_ethtrader AS SELECT * FROM content WHERE subreddit = 'ethtrader';
CREATE VIEW content_ethereum AS SELECT * FROM content WHERE subreddit = 'ethereum';
CREATE VIEW ethtrader_scores AS
  SELECT author, sum(score) as score
  FROM content_ethtrader
  WHERE reddit_created_utc::DATE <= '2017-09-19'
  GROUP BY author
  ORDER BY score DESC;
CREATE VIEW ethereum_scores AS
  SELECT author, sum(score) as score
  FROM content_ethereum
  WHERE reddit_created_utc::DATE <= '2017-09-19'
  GROUP BY author
  ORDER BY score DESC;


CREATE VIEW posts_ethtrader AS SELECT * FROM posts WHERE subreddit = 'ethtrader';
CREATE VIEW posts_ethereum AS SELECT * FROM posts WHERE subreddit = 'ethereum';
CREATE VIEW comments_ethtrader AS SELECT * FROM comments WHERE subreddit = 'ethtrader';
CREATE VIEW comments_ethereum AS SELECT * FROM comments WHERE subreddit = 'ethereum';

CREATE VIEW scores AS
  SELECT
    posts_ethtrader.author,
    sum(posts_ethtrader.score) as ethtrader_posts_score,
    sum(comments_ethtrader.score) as ethtrader_comments_score,
    sum(posts_ethereum.score) as ethereum_posts_score,
    sum(comments_ethereum.score) as ethereum_comments_score
  FROM posts_ethtrader
  FULL OUTER JOIN comments_ethtrader ON (comments_ethtrader.author = posts_ethtrader.author)
  FULL OUTER JOIN posts_ethereum ON (posts_ethereum.author = posts_ethtrader.author)
  FULL OUTER JOIN comments_ethereum ON (comments_ethereum.author = posts_ethtrader.author)
  WHERE
    posts_ethtrader.reddit_created_utc::DATE <= '2017-09-19'
  OR
    comments_ethtrader.reddit_created_utc::DATE <= '2017-09-19'
  OR
    posts_ethereum.reddit_created_utc::DATE <= '2017-09-19'
  OR
    comments_ethereum.reddit_created_utc::DATE <= '2017-09-19'
  GROUP BY posts_ethtrader.author
  ORDER BY ethtrader_posts_score DESC;
