# Changelog

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
