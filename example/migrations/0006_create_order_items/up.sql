-- Line items — the junction table that makes orders <-> products a many-to-many
-- relation. `unit_price` snapshots the price at purchase time.
CREATE TABLE order_items (
  id         INTEGER NOT NULL PRIMARY KEY,
  order_id   INTEGER NOT NULL REFERENCES orders(id),
  product_id INTEGER NOT NULL REFERENCES products(id),
  quantity   INTEGER NOT NULL,
  unit_price REAL    NOT NULL
);
