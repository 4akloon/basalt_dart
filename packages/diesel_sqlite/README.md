# diesel_sqlite

![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5-0175C2?logo=dart&logoColor=white)
![Driver](https://img.shields.io/badge/driver-sqlite3-003B57?logo=sqlite&logoColor=white)
![Part of](https://img.shields.io/badge/part_of-diesel__dart-informational)

**The SQLite backend for [diesel_dart](../../README.md)** — a concrete `SqlDialect` and a
[`package:sqlite3`](https://pub.dev/packages/sqlite3)-backed `Connection`. Depends only on the
dialect-agnostic core ([`diesel`](../diesel)); the same typed DSL, schema, and migrations also run on
[`diesel_postgres`](../diesel_postgres) unchanged.

## Contents

- [Install](#install)
- [Opening a connection](#opening-a-connection)
- [What SqliteConnection implements](#what-sqliteconnection-implements)
- [Transactions](#transactions)
- [Dialect](#dialect)
- [Type mapping](#type-mapping)
- [Introspection](#introspection)
- [Testing tips](#testing-tips)

## Install

```yaml
dependencies:
  diesel:
  diesel_sqlite:
```

`package:sqlite3` uses the system SQLite via FFI. On platforms without a bundled `libsqlite3` (e.g. some
Linux CI images) add [`sqlite3_flutter_libs`](https://pub.dev/packages/sqlite3_flutter_libs) (Flutter) or
install the native library.

## Opening a connection

```dart
import 'package:diesel/diesel.dart';
import 'package:diesel_sqlite/diesel_sqlite.dart';

final db = SqliteConnection.open('app.db');   // file (created if missing)
// final db = SqliteConnection.memory();      // in-memory — ideal for tests

final users = await db.fetch(from(Users.table).map(userMapper.read));
await db.execute(insertInto(Users.table).value(Users.name.set('Bob')));
await db.close();
```

## What SqliteConnection implements

The full [`Connection`](../diesel) interface:

| Method | Notes |
|---|---|
| `fetch(select)` | run a typed `SELECT`, decode each row |
| `execute(write)` | run INSERT/UPDATE/DELETE, return affected-row count |
| `executeReturning(q)` | INSERT/UPDATE/DELETE … `RETURNING`, decode rows |
| `executeSql(sql, [params])` | raw statement (DDL, migrations) |
| `queryRaw(sql, [params])` | raw read → `List<Map<String, Object?>>` |
| `introspect()` | schema → dialect-neutral model (for `print-schema`) |
| `transaction(fn)` | `BEGIN`/`COMMIT`, nested → `SAVEPOINT` |
| `close()` | dispose the database |

The `sqlite3` driver is **synchronous**, so these complete their work eagerly and return already-resolved
futures — the async signatures exist so an async backend (Postgres) can implement the *same* interface
unchanged.

## Transactions

```dart
await db.transaction((tx) async {
  await tx.execute(insertInto(Users.table).value(Users.name.set('Bob')));
  await tx.transaction((inner) async {          // nested → SAVEPOINT
    await inner.execute(insertInto(Users.table).value(Users.name.set('Dave')));
  });
}); // commits on success; rolls back (or releases the savepoint) on error
```

## Dialect

`SqliteDialect` quotes identifiers with double quotes (`"users"."id"`), uses positional `?` placeholders,
and adapts canonical values to the driver form (`bool → 0/1`, `DateTime → epoch-ms`).

## Type mapping

SQLite has no native boolean or timestamp, so:

| Dart | Stored as | Column type |
|---|---|---|
| `int` | `INTEGER` | `SqlType.integer` |
| `String` | `TEXT` | `SqlType.text` |
| `double` | `REAL` | `SqlType.real` |
| `bool` | `INTEGER` `0`/`1` | `SqlType.boolean` |
| `DateTime` | `INTEGER` epoch-ms | `SqlType.dateTime` |
| `List<int>` | `BLOB` | `SqlType.blob` |

Because `bool`/`DateTime` are indistinguishable from `int` at the storage level, `introspect()` (and thus
`print-schema`) reports them as `int`. Full details and the cross-backend story:
[type mapping](../../docs/type-mapping.md).

## Introspection

`introspect()` reads `sqlite_master` + `PRAGMA table_info` / `PRAGMA foreign_key_list` into a
dialect-neutral `List<IntrospectedTable>` (excluding `sqlite_*` and `__diesel_schema_migrations`). This is
what `diesel_dart print-schema` consumes.

## Testing tips

`SqliteConnection.memory()` gives a fast, isolated database per test — no files, no cleanup:

```dart
final db = SqliteConnection.memory();
await db.executeSql('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
// … assert on db.fetch / db.execute …
await db.close();
```
