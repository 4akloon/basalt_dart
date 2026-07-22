# Changelog

## 0.1.0

- Requires `basalt >=0.1.0 <0.2.0` — the new table-marker shape
  (`final class X extends TableRef<X>` with owner-linked columns).
- Raised the driver lower bound to `postgres ^3.5.0` — the connection uses
  `TxSession`, which older 3.x versions don't ship (fixes downgrade analysis).
- No functional changes.

## 0.0.2

- `PostgresDialect.castType` — implements the new `SqlDialect` seam, mapping the core types to
  native Postgres names (`IntSqlType` → `bigint`, `DateTimeSqlType` → `timestamptz`, ...) so the
  `VALUES` table of a batch `updateAll` stays preparable; unwraps `NullableSqlType`.
- `PostgresTypedSqlType` — new opt-in interface for custom codecs to name their native type;
  implemented by `PostgresJsonbSqlType` (`jsonb`), `PostgresUuidSqlType` (`uuid`),
  `PostgresNumericSqlType` (`numeric`) and `PostgresArraySqlType` (common element types).
- Requires `basalt >=0.0.2 <0.1.0`.

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
