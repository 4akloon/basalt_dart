-- Delivery addresses. One customer may own many addresses (one-to-many).
CREATE TABLE addresses (
  id          INTEGER NOT NULL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(id),
  label       TEXT    NOT NULL,
  city        TEXT    NOT NULL,
  street      TEXT    NOT NULL
);
