# diesel_sqlite

The **SQLite backend** for [diesel_dart](../../README.md): a concrete `SqlDialect` and a
[`package:sqlite3`](https://pub.dev/packages/sqlite3)-backed `Connection`. Depends only on the
dialect-agnostic core ([`diesel`](../diesel)).

## Usage

```dart
import 'package:diesel/diesel.dart';
import 'package:diesel_sqlite/diesel_sqlite.dart';

final db = SqliteConnection.open('app.db');   // file
// final db = SqliteConnection.memory();      // in-memory (ideal for tests)

final users = await db.fetch(from(Users.table).map(userMapper.read));
await db.execute(insertInto(Users.table).value(Users.name.set('Bob')));
await db.transaction((tx) async { /* nested calls become SAVEPOINTs */ });
await db.close();
```

`SqliteConnection` implements the full `Connection` interface: `fetch`, `execute`, `executeSql`, `queryRaw`,
`introspect`, `transaction` (BEGIN/COMMIT, nested → SAVEPOINT), and `close`. The `sqlite3` driver is
synchronous, so these complete eagerly and return already-resolved futures — the async signatures exist so an
async backend can implement the same interface unchanged.

## Dialect

`SqliteDialect` quotes identifiers with double quotes (`"users"."id"`) and uses positional `?` placeholders.

## Type mapping

SQLite has no native boolean or timestamp, so `bool` is stored as `INTEGER` (`0`/`1`) and `DateTime` as
`INTEGER` epoch milliseconds. `introspect()` reports SQLite affinities into the canonical `ColumnType` model;
since `bool`/`timestamp` are indistinguishable from `int`/`text` at the storage level, generated schemas use
`int`/`String` for them. See [type-mapping](../../docs/type-mapping.md).

## Introspection

`introspect()` reads `sqlite_master` + `PRAGMA table_info` / `PRAGMA foreign_key_list` into a dialect-neutral
`List<IntrospectedTable>` (excluding `sqlite_*` and `__diesel_schema_migrations`). This is what
`diesel_dart print-schema` consumes.
