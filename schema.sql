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
  joined TIMESTAMP WITHOUT TIME ZONE,
  address VARCHAR
);

-- ALTER TABLE users ADD COLUMN joined TIMESTAMP WITHOUT TIME ZONE;
-- ALTER TABLE users ADD COLUMN address VARCHAR;

CREATE TABLE IF NOT EXISTS reg_comments (
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  comment_id VARCHAR PRIMARY KEY,
  replied BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS reg_inbox (
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  message_id VARCHAR PRIMARY KEY,
  replied BOOLEAN DEFAULT false
);

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
CREATE INDEX comment_post_id ON comments (post_id);

CREATE TYPE content_type AS ENUM ('POST', 'COMMENT');

CREATE TABLE IF NOT EXISTS tips (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  event_id VARCHAR NOT NULL UNIQUE,
  content_type content_type NOT NULL,
  reddit_id VARCHAR NOT NULL,
  token VARCHAR,
  amount NUMERIC,
  from_address VARCHAR NOT NULL,
  reply_id VARCHAR
);

CREATE INDEX tips_reddit_id ON tips (reddit_id);

CREATE TABLE IF NOT EXISTS flips (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  event_id VARCHAR NOT NULL UNIQUE,
  reddit_id VARCHAR NOT NULL,
  reply_id VARCHAR
);
