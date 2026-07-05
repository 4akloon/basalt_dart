# Query Builder

`Query` is the entry point for reads: `from(source)` starts a query, refine it
with `.where(...)`, `.join(...)`, `.orderBy(...)`, `.limit(...)`, then finish
with `.map(decoder)`.

```dart
final q = from(Users.table)
    .where(Users.age > 18)
    .orderBy(Users.name.asc())
    .limit(20)
    .map((r) => User(r.get(Users.id), r.get(Users.name), r.get(Users.age), r.get(Users.active)));
// q is a MappedQuery<User> — pass it to db.fetch, or use .load(db).
```

- **`from(QuerySource)`** — a `TableRef` or a `TableAlias`. Single-table
  queries are `Query<Tbl>`, which keeps `where` compile-time scoped.
- **Projection is automatic** (all columns of the involved tables). Narrow it
  with `.select([Users.name, Users.age])`.
- **`.map((RowReader r) => …)`** decides the result shape — scalar, record,
  data class, nested objects. **`.mapWith(rowMapper)`** is sugar for
  `.map(rowMapper.read)`.

## Two-tier join safety

- **Single-table** queries are fully compile-time scoped:
  `from(Users.table).where(Posts.id.eq(1))` does not compile.
- **Joined** queries relax to `Query<Object?>`; `QueryBuilder` validates at
  build time that every referenced table/alias is in the FROM/JOIN clause,
  throwing `StateError` otherwise.

## Joins

```dart
// FK-driven: ON is derived from the Ref (posts.author_id = users.id).
from(Posts.table)
    .leftJoin(Users.table, onFk: Posts.authorId)
    .map((r) => '${r.get(Posts.title)} <- ${r.get(Users.name)}');

// Explicit ON with eqColumn (required for self-joins).
final mgr = Users.table.aliased('mgr');
from(Users.table)
    .innerJoin(mgr, on: Users.managerId.eqColumn(mgr.col(Users.id)))
    .map((r) => '${r.get(Users.name)} -> ${r.get(mgr.col(Users.name))}');
```

- `innerJoin` / `leftJoin` take either `on:` (an `Expression<bool>`) or
  `onFk:` (a `Ref` column).
- Joins **chain** freely; the projection auto-expands with the joined table's
  columns.
- **Self-joins** use aliases: `Users.table.aliased('mgr')`, then
  `mgr.col(Users.id)`. `RowReader` keys by the alias, so `mgr.id` ≠ `users.id`.
- Generated relation queries (`@Relation`) do all of this for you — see
  **Annotations & Codegen**.

## Reading rows

`RowReader` reads a result row by **selection key** — columns by `table.name`
(alias-aware), aggregates by alias — never by positional index. Reading a
column that isn't in the projection throws `StateError`.

```dart
.map((r) => '${r.get(Posts.title)} (${r.get(Posts.views)})')
```

`MappedQuery` and `RowMapper` wrap a `Query` with a row-shape mapping function.
`MappedQueryExecute` adds basalt-style terminals:

| Method | Effect |
|---|---|
| `.load(db)` | all rows |
| `.first(db)` | first row, throws if empty |
| `.optional(db)` | first row or `null` |

## Aggregates & grouping

Aggregate helpers are *selections* — pass them to `.select([...])` and read
them back with the same handle:

```dart
final total = countAll();
final n = await from(Users.table).select([total]).map((r) => r.get(total)).first(db);

final sumAge = Users.age.sum();
final avgAge = Users.age.avg();
final (s, a) = await from(Users.table)
    .select([sumAge, avgAge])
    .map((r) => (r.get(sumAge), r.get(avgAge)))
    .first(db);
```

`GROUP BY` + `HAVING`:

```dart
final perAuthor = Posts.views.sum();
final rows = await from(Posts.table)
    .select([Posts.authorId, perAuthor])
    .groupBy([Posts.authorId])
    .having(perAuthor.gt(100))
    .map((r) => (r.get(Posts.authorId), r.get(perAuthor)))
    .load(db);
```

`SELECT DISTINCT` via `.distinct()`:

```dart
final kinds = await from(Users.table)
    .select([Users.active])
    .distinct()
    .map((r) => r.get(Users.active))
    .load(db);
```

> Aggregate result types: `count`/`countAll` → `int`; `sum`/`min`/`max` →
> `int?`; `avg` → `double?`. Non-int numeric columns are not yet supported.

## `@HasMany` fold queries (one SQL + JOIN)

Codegen for `@HasMany` emits a `FoldMappedQuery<T>` getter: one `SELECT` with
`LEFT JOIN`s for children (and nested children), then a generated
`$ClassFold(List<RowReader>)` that dedupes the cartesian product into parent
rows with `List<Child>` fields.

```dart
// Generated — one round-trip via Connection.fetch, fold in Dart.
final rows = await customerProfileRowQuery
    .order(Customers.name.asc())
    .limit(50)
    .load(db);
```

- **`.mapFold(folder)`** — after manual JOINs, same pattern without codegen.
- **`.load(db)`** / **`.optional(db)`** / **`.first(db)`** — on
  `FoldMappedQuery` via `FoldMappedQueryExecute` (`fold(await db.fetch(this))`).
- **Parent `limit` / `offset`** — not SQL `LIMIT` on flat JOIN rows; the
  serializer adds `WHERE root_pk IN (SELECT … ORDER BY … LIMIT/OFFSET)`. Call
  **`.withRootPk(rootPk)`** before `.limit()` / `.offset()`.
- **Do not** use `.distinct()` or `GROUP BY` on a fold query — deduping belongs
  in the folder.

## Associations (grouped child loads)

`loadGroupedByFk` loads the children of many parents in one query and groups
them by foreign key — avoids N+1:

```dart
final users = await from(Users.table).map(userMapper.read).load(db);
final postsByAuthor = await loadGroupedByFk(
  db, Posts.table, Posts.authorId, users.map((u) => u.id).toList(), readPost);
// Map<int, List<Post>>; every author id is present (empty list if no posts).
```

## basalt-style aliases

| basalt | basalt_dart |
|---|---|
| `users.filter(p)` | `from(Users.table).filter(p)` — ANDs repeated calls |
| `.order(col.asc())` | `.order(Users.col.asc())` — alias for `orderBy` |
| `col.eq_any([...])` | `Users.col.eqAny([...])` — alias for `isIn` |
| `query.load(conn)` | `query.load(db)` |
| `query.first(conn)` | `query.first(db)` — throws if no rows |
| `query.first(conn).optional()` | `query.optional(db)` — `null` if no rows |
| `users.find(1)` | `from(Users.table).findBy(Users.id, 1)` |

```dart
final adults = await from(Users.table)
    .filter(Users.age.ge(18))
    .order(Users.name.asc())
    .map(userMapper.read)
    .load(db);
```
