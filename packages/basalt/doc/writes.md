# Writes

`WriteStatement` is the `sealed` base for the three write builders:

- `InsertStatement` — `insertInto(Table).values(...)`, with `OnConflict` for
  upserts (`DO NOTHING` / `DO UPDATE`, including `setToExcluded()` to pull the
  conflicting row's value).
- `UpdateStatement` — `update(Table).set([...]).where(...)`.
- `DeleteStatement` — `deleteFrom(Table).where(...)`.

Assignments use `TableColumn.set(value)`, which pins the value type to the
column's static type — `Users.age.set('x')` is a compile error, not a runtime
one.

## RETURNING

Any write statement can add `.returning([...]).map(...)` to become a
`ReturningQuery`, read back through `Returning` the same way a `SELECT` is —
by selection key, via `RowReader`.

```dart
final inserted = await connection.executeReturning(
  insertInto(Users).values({Users.name.set('Ada')}).returning(
    [Users.id],
  ).map((r) => r.read(Users.id)),
);
```
