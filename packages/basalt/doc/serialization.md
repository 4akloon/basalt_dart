# Serialization

`QueryBuilder` is the pure transformation from a typed AST (`Query` /
`WriteStatement`) into a `CompiledQuery` — `(String sql, List<Object?> params)`
— by walking the AST and delegating dialect-specific syntax to `SqlDialect`
(quoting, parameter placeholders, `RETURNING`/`ON CONFLICT` spelling, …).

Because this step has **zero driver dependency**, it's trivially
unit-testable in isolation: build a query, serialize it, assert on the SQL
string and params — no database required. See
`packages/basalt/test/serializer_test.dart` for the full suite (SQL/params,
scope validation, joins).

## Scope validation

Before emitting SQL, the builder validates that every table referenced by a
column, join condition, or predicate is actually present in the query's
`FROM`/`JOIN` clauses. A query built with an out-of-scope table throws
`StateError` at *build* time — never as a malformed SQL string sent to the
database.

## Adding a new backend

A new backend package implements `Connection` + `SqlDialect` (plus
`introspect()`), then plugs into `ConnectionFactory.open` by URL scheme — no
changes to the core builder or CLI are required. See **Connection &
Backends**.
