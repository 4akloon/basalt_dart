-- Free-form JSON attributes per product, stored as TEXT on SQLite (a Postgres
-- backend would use `jsonb`). The typed schema maps this column to the custom
-- `JsonMapOrNullSqlType` codec via the `types:` override in basalt.yaml.
ALTER TABLE products ADD COLUMN metadata TEXT;
