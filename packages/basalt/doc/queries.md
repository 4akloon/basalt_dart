# Query Builder

`Query` is the entry point for reads: `from(Table)` starts a query, and
`.where(...)`, `.join(...)`, `.orderBy(...)`, `.limit(...)` refine it
immutably (each call returns a new `Query`).

```dart
final query = from(Users)
    .where(Users.age.gt(18))
    .join(Posts, on: Posts.authorId.eqColumn(Users.id))
    .select((u, p) => (u.name, p.title));
```

## Two-tier join safety

- Single-table `from(t)` is `Query<Tbl>` — `where` is compile-time-scoped to
  that table's columns.
- After a join the scope relaxes to `Query<Object?>`; `QueryBuilder` validates
  at build time (via `_validateScope`) that every referenced table is in the
  `FROM`/`JOIN` clause, throwing `StateError` otherwise.

## Reading rows

`RowReader` reads a result row by **selection key** — columns by
`table.name` (alias-aware), aggregates by alias — never by positional index.
This keeps mapping order-independent and join-safe. The projection itself is a
`List<Selection>` (columns or `Aggregate`s); the serializer only ever consumes
AST-level `Projection`s, so it stays completely schema-free.

`MappedQuery` and `RowMapper` wrap a `Query` with a row-shape mapping
function, produced by `.select(...)`; `MappedQueryExecute` (an extension) adds
the `Connection`-bound `.fetch()` convenience.
