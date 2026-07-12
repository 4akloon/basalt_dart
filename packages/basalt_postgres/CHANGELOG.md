# Changelog

## 0.0.1

Initial development release of the Postgres backend for basalt_dart.

- `PostgresDialect` — the `SqlDialect` implementation with `$N` placeholders and quoted
  identifiers.
- `PostgresConnection` — an async `Connection` over `package:postgres` with transactions and
  nested `SAVEPOINT` support.
- `information_schema` introspection for the CLI's `generate-schema`.
- `PostgresAdapter` / `PostgresEndpoint` (`lib/adapter.dart`) — the `BasaltAdapter` CLI seam.
- Native `PostgresJsonbSqlType`.

> **Status:** the driver-backed `Connection` and introspection are a work in progress; some
> native types (uuid, json, numeric, arrays) are not yet mapped.
