# Query DSL

The builder is a pure transformation into `(sql, params)`; a [`Connection`](#execution) runs it. Examples use
the `Users`/`Posts` schema from [`example/`](../example).

## Building a SELECT

Start with `from(source)`, refine, then finish with `.map(decoder)`:

```dart
final q = from(Users.table)            // Query<Users>
    .where(Users.age > 18)
    .orderBy(Users.name.asc())
    .limit(20)
    .offset(0)
    .map((r) => User(r.get(Users.id), r.get(Users.name), r.get(Users.age), r.get(Users.active)));
// q is a MappedQuery<User> (a SelectQuery<User>) — pass it to db.fetch.
```

- **`from(QuerySource)`** — a `TableRef` or a `TableAlias`. Single-table queries are `Query<Tbl>`, which keeps
  `where` compile-time scoped to that table.
- **Projection is automatic** (all columns of the involved tables). Narrow it with
  `.select([Users.name, Users.age])`.
- **`.map((RowReader r) => …)`** decides the result shape — a scalar, a record, a data class, nested objects.
  This single terminal replaces any `selectN`/`selectJoinN` family.
- **`.mapWith(rowMapper)`** is sugar for `.map(rowMapper.read)` using a generated/ reusable `RowMapper`.

## RowReader

Inside `.map`, read values **by column** (not by position) with `r.get(column)`:

```dart
.map((r) => '${r.get(Posts.title)} (${r.get(Posts.views)})')
```

`RowReader` keys by `table.name` (alias-aware), so column order and joins never matter. Reading a column that
isn't in the projection throws a `StateError`.

## Predicates

All return `Expression<bool, Tbl>`:

| Method | SQL |
|---|---|
| `col.eq(v)` / `col.ne(v)` | `= ?` / `<> ?` |
| `col.gt/ge/lt/le(v)` | `> ? / >= ? / < ? / <= ?` |
| `col > v`, `col < v`, `col >= v`, `col <= v` | operator sugar for the above |
| `col.isIn([...])` | `IN (?, ?, …)` |
| `col.between(lo, hi)` | `BETWEEN ? AND ?` |
| `col.isNull()` / `col.isNotNull()` | `IS NULL` / `IS NOT NULL` |
| `col.like('%a%')` | `LIKE ?` (text columns only) |
| `a.eqColumn(b)` | `a = b` (column-to-column; shared key type enforced) |

Combine predicates with `&` (AND) / `\|` (OR), or `.and()` / `.or()`:

```dart
from(Users.table).where((Users.age > 28) & Users.active.eq(1));
```

> **Gotcha:** chaining `.where(a).where(b)` **replaces** the predicate (the last one wins) — it does *not*
> AND them. Always combine in a single `.where(...)` with `&`/`|`.

## Ordering, limit, offset

```dart
from(Users.table).orderBy(Users.age.desc()).limit(2).offset(0);
```

`col.asc()` / `col.desc()` produce `Ordering`s.

## Joins

```dart
// FK-driven: the ON is derived from the Ref (posts.author_id = users.id).
from(Posts.table)
    .leftJoin(Users.table, onFk: Posts.authorId)
    .map((r) => '${r.get(Posts.title)} <- ${r.get(Users.name)}');

// Explicit ON with eqColumn (required for self-joins).
final mgr = Users.table.aliased('mgr');
from(Users.table)
    .innerJoin(mgr, on: Users.managerId.eqColumn(mgr.col(Users.id)))
    .map((r) => '${r.get(Users.name)} -> ${r.get(mgr.col(Users.name))}');
```

- `innerJoin` / `leftJoin` take either `on:` (an `Expression<bool>`) or `onFk:` (a `Ref` column).
- Joins **chain** freely; the projection auto-expands with the joined table's columns.
- **Self-joins / multiple FKs to one table** use aliases: `Users.table.aliased('mgr')`, then address columns
  via `mgr.col(Users.id)`. The serializer emits `"users" AS "mgr"` and `RowReader` keys by the alias, so
  `mgr.id` ≠ `users.id`.
- Generated relation queries (`@Relation`) do all of this for you — see [derives.md](derives.md).

### Scope safety (two tiers)

- **Single-table** queries are fully compile-time scoped: `from(Users.table).where(Posts.id.eq(1))` does not
  compile.
- **Joined** queries relax to `Query<Object?>`; the serializer then validates at build time that every
  referenced table/alias is in the FROM/JOIN clause, throwing `StateError` otherwise.

## Writes

```dart
await db.execute(insertInto(Users.table)
    .value(Users.name.set('Bob'))
    .value(Users.age.set(30)));

await db.execute(update(Users.table)
    .value(Users.active.set(1))
    .where(Users.id.eq(3)));

await db.execute(deleteFrom(Posts.table).where(Posts.views.lt(10)));
```

Values go through `column.set(value)`, whose type is pinned by the column — `Users.age.set('x')` is a compile
error. `@Insertable` / `@AsChangeset` generate `toInsert()` / `toUpdate()` so you can write whole objects
(see [derives.md](derives.md)).

## Execution

```dart
final db = SqliteConnection.open('app.db');     // or SqliteConnection.memory()

await db.fetch(selectQuery);                     // Future<List<R>>
await db.execute(writeStatement);               // Future<int> (affected rows)
await db.executeSql('VACUUM');                   // raw DDL/SQL
await db.queryRaw('SELECT count(*) AS n FROM users');  // List<Map<String,Object?>>
await db.transaction((tx) async { /* … */ });   // BEGIN/COMMIT, nested = SAVEPOINT
await db.close();
```

The API is async-first; SQLite returns completed futures, and an async backend (Postgres) implements the same
`Connection` interface unchanged.
