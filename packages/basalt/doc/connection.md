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
- `transaction` commits on success and rolls back on error (see below).

## Transactions

`transaction` hands your callback a **distinct, transaction-scoped
`Connection`** — use that `tx` handle for statements inside the block, not the
original connection:

```dart
await db.transaction((tx) async {
  final id = await tx.executeReturning(
    insertInto(Orders.table).value(Orders.total.set(42)).returning([Orders.id]),
  );
  await tx.execute(insertInto(LineItems.table).value(LineItems.orderId.set(id)));
  // returning normally commits; throwing rolls the whole block back.
});
```

- **Nesting is decided by the handle, not a counter.** Calling `transaction`
  again on the `tx` handle opens a nested `SAVEPOINT`, so an inner failure rolls
  back only the inner work while the outer transaction continues:

  ```dart
  await db.transaction((tx) async {
    await tx.execute(/* ... outer write ... */);
    try {
      await tx.transaction((inner) async {
        await inner.execute(/* ... */);
        throw Exception('bail out of inner only');
      });
    } on Exception {
      // outer transaction still commits
    }
  });
  ```

- **Concurrent top-level transactions are serialized.** Two `transaction` calls
  on one connection never interleave their statements: the second queues until
  the first commits or rolls back. (On SQLite every operation shares one lock;
  on Postgres this is the driver's native `runTx` behaviour, and the raw
  connection throws if used while a transaction is active.)
- The `tx` handle is only valid for the duration of the callback; using it after
  the block returns — or calling `tx.close()` — throws `StateError`.

## Backends

| Package | Driver |
|---|---|
| `basalt_sqlite` | `package:sqlite3` |
| `basalt_postgres` | `package:postgres` |

Both implement this same interface, so application code written against
`Connection` runs unchanged against either backend.
