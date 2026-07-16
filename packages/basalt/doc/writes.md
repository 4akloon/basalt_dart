# Writes

`WriteStatement` is the `sealed` base for the four write builders:

- `InsertStatement` — `insertInto(Table).value(...)` / `.values([...])`, with
  `OnConflict` for upserts.
- `UpdateStatement` — `update(Table).set(...).where(...)`.
- `UpdateAllStatement` — `updateAll(Table).keyedBy(...).values([...])`, a batch
  update: many rows, per-row values, one statement.
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

Composes with RETURNING to get one row back per inserted row. `@Insertable`
also generates this form for whole lists — `myUserWrites.toInsert()` on any
`Iterable` of the annotated class builds one multi-row insert.

## Batch update

`updateAll` updates many rows with *different* values in a single statement:
it joins the table against a `VALUES` list on the key column(s), so a
1000-row update is one round-trip, not 1000.

```dart
final affected = await db.execute(
  updateAll(Products.table).keyedBy(Products.id).values([
    for (final p in restocked)
      [Products.id.set(p.id), Products.stock.set(p.stock)],
  ]),
);
```

which serializes to

```sql
WITH "__basalt_values"("id", "stock") AS (VALUES (?, ?), (?, ?), ...)
UPDATE "products" SET "stock" = "__basalt_values"."stock"
FROM "__basalt_values"
WHERE "products"."id" = "__basalt_values"."id"
```

- Every row must include the key column(s); the remaining columns become the
  `SET` clause. `keyedBy` can be called repeatedly for a composite key.
- Key values must be unique within one batch — SQL leaves it undefined which
  `VALUES` row wins when several match the same target row.
- Rows whose key matches nothing update nothing; the affected count covers
  matched rows only.
- `.where(...)` adds an extra predicate on top of the key join (e.g. only
  touch rows that are still `active`).
- Values are literals (`column.set(v)`); `setExpr`/`setToExcluded` don't fit a
  `VALUES` tuple and throw.
- Composes with RETURNING like any other write.

Backend notes: needs SQLite ≥ 3.33 (`UPDATE ... FROM`, 2020) — anything
`package:sqlite3` ships qualifies. On Postgres the first `VALUES` row is
emitted with `CAST`s so the statement's parameter types stay inferable (see
`SqlDialect.castType` in **Serialization**). One statement binds
`rows × columns` parameters and the Postgres wire protocol caps a statement at
65 535 — chunk truly huge batches.

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
