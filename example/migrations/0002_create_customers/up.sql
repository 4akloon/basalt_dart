-- Shop customers. `loyalty_tier` is a TEXT enum (bronze/silver/gold) and
-- `created_at` is epoch milliseconds (SQLite has no native DateTime).
CREATE TABLE customers (
  id           INTEGER NOT NULL PRIMARY KEY,
  name         TEXT    NOT NULL,
  email        TEXT    NOT NULL UNIQUE,
  loyalty_tier TEXT    NOT NULL DEFAULT 'bronze',
  created_at   INTEGER NOT NULL
);
