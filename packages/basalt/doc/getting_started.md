# Getting Started

Basalt is a type-safe query builder and ORM for Dart. It separates **building**
a query from **executing** it:

- The query builder is a pure transformation of a typed AST into
  `(String sql, List<Object?> params)` — see `QueryBuilder` and `SqlDialect`.
  It has zero driver dependency, which makes it trivially unit-testable.
- A `Connection` implementation serializes and runs the result against a real
  driver (e.g. `basalt_sqlite`, `basalt_postgres`).

## A minimal query

```dart
abstract final class Users extends TableRef<Users> {
  static const id = PrimaryKey<int, Users>('id');
  static const name = ValueColumn<String, Users>('name');
}

final rows = await connection.fetch(
  from(Users).where(Users.name.eq('Ada')).select((u) => u.name),
);
```

## Where to go next

See the sidebar topics for a deeper dive:

- **Schema** — columns, table markers, and selections.
- **Expressions** — predicates and combinators.
- **Query Builder** — `from`, `where`, joins, reading rows.
- **Writes** — `insertInto` / `update` / `deleteFrom`.
- **Serialization** — the AST → SQL pipeline.
- **Connection & Backends** — running queries against a database.
- **Annotations & Codegen** — deriving models with `build_runner`.
