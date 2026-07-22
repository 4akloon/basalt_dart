# Changelog

## 0.1.0

- Requires `basalt >=0.1.0 <0.2.0` — the new table-marker shape
  (`final class X extends TableRef<X>` with owner-linked columns).
- Declares supported platforms explicitly (Android, iOS, Linux, macOS,
  Windows): the `package:sqlite3` FFI entrypoint rules out the web target, and
  the explicit set removes the partial web-without-WASM platform score.
- No functional changes.

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
