# Changelog

## 0.0.2

- `SqliteDialect.castType` — implements the new `SqlDialect` seam; SQLite is dynamically typed,
  so it never asks for a cast (`null`).
- Supports the core's new batch `updateAll` statement (`UPDATE ... FROM`, needs SQLite ≥ 3.33).
- Requires `basalt >=0.0.2 <0.1.0`.

## 0.0.1

Initial development release of the SQLite backend for basalt_dart.

- `SqliteConnection` — an async-first `Connection` over `package:sqlite3` (`open`/`memory`),
  running synchronously and returning completed futures.
- `SqliteDialect` — the `SqlDialect` implementation (identifier quoting, `?` placeholders,
  `RETURNING`-free counts).
- Transactions with nested `SAVEPOINT` support and rollback on error.
- `introspect()` over `sqlite_master`/`PRAGMA` for the CLI's `generate-schema`.
- `SqliteAdapter` (`lib/adapter.dart`) — the `BasaltAdapter` CLI seam with `open`/`reset` and
  default type-override presets.
