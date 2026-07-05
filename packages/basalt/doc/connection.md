# Connection & Backends

`Connection` is the database-agnostic execution surface. The query builder
produces statements; a `Connection` implementation serializes (via
`QueryBuilder`/`SqlDialect`) and runs them against a real driver.

## Async-first, sync-compatible

Every method returns a `Future`; `FutureOr` appears only on the
`transaction` callback. This is deliberate: SQLite runs synchronously under
the hood and simply returns already-completed futures, while an async driver
(Postgres) implements the exact same signatures unchanged.

```dart
abstract interface class Connection {
  Future<List<R>> fetch<R>(SelectQuery<R> statement);
  Future<int> execute(WriteStatement statement);
  Future<List<R>> executeReturning<R>(ReturningQuery<R> statement);
  Future<void> executeSql(String sql, [List<Object?> params]);
  Future<List<Map<String, Object?>>> queryRaw(String sql, [List<Object?> params]);
  Future<List<IntrospectedTable>> introspect();
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action);
  Future<void> close();
}
```

- `executeSql` / `queryRaw` are the raw-SQL escape hatches (DDL, migrations,
  ad-hoc introspection).
- `introspect()` reads the live schema into the dialect-neutral
  `IntrospectedTable` / `IntrospectedColumn` / `ForeignKey` model, which the
  `basalt_cli` `generate-schema` command turns into typed Dart schema code.
- `transaction` commits on success and rolls back on error; nested calls use
  `SAVEPOINT`s.

## Backends

| Package | Driver |
|---|---|
| `basalt_sqlite` | `package:sqlite3` |
| `basalt_postgres` | `package:postgres` |

Both implement this same interface, so application code written against
`Connection` runs unchanged against either backend.
