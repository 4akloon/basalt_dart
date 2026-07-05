# Expressions

An `Expression` wraps a typed AST node representing a SQL predicate or value
expression. Columns produce them via comparison methods (`eq`, `gt`, `isIn`,
`between`, `isNull`, …) and operator sugar (`>`, `<`, `>=`, `<=`).

## Combining predicates

Boolean expressions combine with `&` (AND) and `|` (OR) via the
`BoolExpression` extension:

```dart
q.where(Users.age.gt(18) & Users.name.isNotNull());
```

> **Gotcha:** chained `.where().where()` **replaces** the predicate — it does
> not AND. Combine with `&`/`|` in a single call, or use `Query.filter`, which
> ANDs onto the existing predicate across repeated calls.

## Scoping

Every `Expression<T, Tbl>` is scoped to a table type `Tbl`. A single-table
query (`from(Users)`) is a `Query<Users>`, so only `Users` columns type-check
in `.where(...)`. After a join the scope relaxes to `Query<Object?>`, and
`QueryBuilder` validates at build time that every referenced table is present
in the `FROM`/`JOIN` clauses — see **Serialization**.
