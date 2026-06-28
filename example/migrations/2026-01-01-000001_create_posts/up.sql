CREATE TABLE posts (
  id        INTEGER NOT NULL PRIMARY KEY,
  author_id INTEGER NOT NULL REFERENCES users(id),
  title     TEXT    NOT NULL,
  views     INTEGER NOT NULL DEFAULT 0
);
