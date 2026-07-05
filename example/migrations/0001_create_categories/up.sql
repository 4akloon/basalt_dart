-- Product categories, organised as a self-referential tree: a category may have
-- a parent (NULL for top-level roots), so `parent_id` references this same table.
CREATE TABLE categories (
  id        INTEGER NOT NULL PRIMARY KEY,
  name      TEXT    NOT NULL,
  parent_id INTEGER          REFERENCES categories(id)
);
