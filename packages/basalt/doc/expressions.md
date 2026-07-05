# Expressions

An `Expression` wraps a typed AST node representing a SQL predicate or value
expression. Columns produce them via comparison methods and operator sugar.

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

Combine predicates with `&` (AND) / `|` (OR), or `.and()` / `.or()`:

```dart
from(Users.table).where((Users.age > 28) & Users.active.eq(1));
```

> **Gotcha:** chained `.where(a).where(b)` **replaces** the predicate (last wins)
> — use a single `.where(...)` with `&`/`|`, or use `.filter(...)`, which **ANDs**
> repeated calls (`filter(a).filter(b)` ⇒ `WHERE a AND b`).

## Scoping

Every `Expression<T, Tbl>` is scoped to a table type `Tbl`. A single-table
query (`from(Users)`) is a `Query<Users>`, so only `Users` columns type-check
in `.where(...)`. After a join the scope relaxes to `Query<Object?>`, and
`QueryBuilder` validates at build time that every referenced table is present
in the `FROM`/`JOIN` clauses — see **Serialization**.

## Raw SQL fragments

For expressions the builder doesn't model, `rawCondition(sql)` is a boolean
fragment for `having` (or a joined `where`/`filter`). Use `?` placeholders +
`params`:

```dart
from(Users.table).having(rawCondition('count(*) > ?', params: [10]));
```

For typed selections in the projection, see `raw<T>(...)` in **Schema**.
