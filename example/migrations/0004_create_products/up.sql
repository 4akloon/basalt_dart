-- Catalogue products. `price` is REAL, `is_active` is a 0/1 boolean, and every
-- product belongs to exactly one category.
CREATE TABLE products (
  id          INTEGER NOT NULL PRIMARY KEY,
  name        TEXT    NOT NULL,
  description TEXT    NOT NULL,
  price       REAL    NOT NULL,
  stock       INTEGER NOT NULL DEFAULT 0,
  category_id INTEGER NOT NULL REFERENCES categories(id),
  is_active   INTEGER NOT NULL DEFAULT 1
);
