# Changelog

## 0.0.1

Initial development release of the Postgres backend for basalt_dart.

- `PostgresDialect` — the `SqlDialect` implementation with `$N` placeholders and quoted
  identifiers.
- `PostgresConnection` — an async `Connection` over `package:postgres` with transactions and
  nested `SAVEPOINT` support.
- `information_schema` introspection (tables, columns, nullability, primary & foreign keys;
  arrays keyed by `udt_name`) for the CLI's `generate-schema`.
- `PostgresAdapter` / `PostgresEndpoint` (`lib/adapter.dart`) — the `BasaltAdapter` CLI seam.
- Native PG type codecs, emitted by the adapter's `native_types` preset: `PostgresJsonbSqlType`
  (`json`/`jsonb`), `PostgresUuidSqlType` (`uuid`), `PostgresNumericSqlType` (exact decimal as
  `String`), and `PostgresArraySqlType<E>` (`integer[]`/`text[]`/`double[]`/`boolean[]`, …).
