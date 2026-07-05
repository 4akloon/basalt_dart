-- Customer orders. `status` is a TEXT enum, `shipping_address_id` is a nullable
-- FK (a draft order may not have an address yet), `created_at` is epoch millis.
CREATE TABLE orders (
  id                  INTEGER NOT NULL PRIMARY KEY,
  customer_id         INTEGER NOT NULL REFERENCES customers(id),
  status              TEXT    NOT NULL DEFAULT 'pending',
  shipping_address_id INTEGER          REFERENCES addresses(id),
  created_at          INTEGER NOT NULL
);
