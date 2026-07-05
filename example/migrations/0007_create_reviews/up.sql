-- Product reviews written by customers (1..5 stars). Both `product_id` and
-- `customer_id` are foreign keys, so a review belongs to two parents.
CREATE TABLE reviews (
  id          INTEGER NOT NULL PRIMARY KEY,
  product_id  INTEGER NOT NULL REFERENCES products(id),
  customer_id INTEGER NOT NULL REFERENCES customers(id),
  rating      INTEGER NOT NULL,
  comment     TEXT,
  created_at  INTEGER NOT NULL
);
