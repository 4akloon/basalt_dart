# Writes

`WriteStatement` is the `sealed` base for the three write builders:

- `InsertStatement` — `insertInto(Table).value(...)` / `.values([...])`, with
  `OnConflict` for upserts.
- `UpdateStatement` — `update(Table).set(...).where(...)`.
- `DeleteStatement` — `deleteFrom(Table).where(...)`.

Values go through `column.set(value)`, whose type is pinned by the column —
`Users.age.set('x')` is a compile error. `@Insertable` / `@AsChangeset`
generate `toInsert()` / `toUpdate()` for whole objects — see **Annotations &
Codegen**.

```dart
await db.execute(insertInto(Users.table)
    .value(Users.name.set('Bob'))
    .value(Users.age.set(30)));

await db.execute(update(Users.table)
    .value(Users.active.set(1))
    .where(Users.id.eq(3)));

await db.execute(deleteFrom(Posts.table).where(Posts.views.lt(10)));
```

## Batch insert

Insert several rows in one statement with `.values([...])` — columns are taken
from the first row (don't mix with the single-row `.value(...)`):

```dart
await db.execute(insertInto(Users.table).values([
  [Users.name.set('A'), Users.age.set(20), Users.active.set(true)],
  [Users.name.set('B'), Users.age.set(21), Users.active.set(false)],
]));
```

Composes with RETURNING to get one row back per inserted row.

## RETURNING

Get columns back from a write with `.returning([...]).map(...)` run via
`db.executeReturning(...)` — handy for database-generated ids:

```dart
final ids = await db.executeReturning(
  insertInto(Users.table)
      .value(Users.name.set('Bob'))
      .returning([Users.id])
      .map((r) => r.get(Users.id)),
);
final newId = ids.single;
```

Works for UPDATE/DELETE too. RETURNING columns are read back by selection key
through `RowReader`.

## Upsert (ON CONFLICT)

`insertInto(...).onConflict([cols])` then `.doNothing()` or `.doUpdate([...])`:

```dart
// Ignore duplicates.
await db.execute(insertInto(Users.table)
    .value(Users.id.set(1)).value(Users.name.set('Bob'))
    .onConflict([Users.id]).doNothing());

// Replace on conflict: setToExcluded() takes the value from the row that failed
// to insert; set(v) uses a literal.
await db.execute(insertInto(Users.table)
    .value(Users.id.set(1)).value(Users.name.set('Bob'))
    .onConflict([Users.id])
    .doUpdate([Users.name.setToExcluded(), Users.age.set(0)]));
```

## Raw SQL escape hatch

For full escape hatches, use `Connection.executeSql` / `queryRaw`. For typed
fragments in writes, see `raw<T>(...)` and `rawCondition(...)` in **Schema**
and **Expressions**.
