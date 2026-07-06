# Getting Started

`basalt_sqlite` provides `SqliteConnection` and `SqliteDialect` — the SQLite
backend for `package:basalt`.

## Open a database

```dart
import 'package:basalt_sqlite/basalt_sqlite.dart';

// File-backed (creates the file if missing).
final db = SqliteConnection.open('app.db');

// In-memory — ideal for tests.
final mem = SqliteConnection.memory();
```

## Run queries

Use the same query builder and generated mappers as with any backend:

```dart
import 'package:basalt/basalt.dart';

final rows = await db.fetch(
  from(Users.table).where(Users.age > 18).mapWith(UserQuery.mapper),
);

await db.execute(user.toInsert());

await db.transaction((tx) async {
  await tx.execute(/* … */);
});

await db.close();
```

The API is async-first; SQLite runs synchronously under the hood and returns
already-completed futures, so an async Postgres backend implements the exact
same `Connection` signatures unchanged.

## Dialect

`SqliteDialect` uses double-quoted identifiers and positional `?` placeholders.
`encodeParam` maps `bool`→`int` and `DateTime`→epoch milliseconds for the
sqlite3 driver. See **Type Mapping** for SQLite storage caveats.

## Introspection

`SqliteConnection.introspect()` reads `PRAGMA table_info` and foreign-key
metadata into the dialect-neutral `IntrospectedTable` model, consumed by
`basalt_cli generate-schema`.
