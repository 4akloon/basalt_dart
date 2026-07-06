# Type Mapping (SQLite)

SQLite-specific caveats on top of the core codec model in `basalt` **Types**.

## No native boolean or timestamp

SQLite has no native boolean or timestamp type. As a result:

- A `bool` column is declared `INTEGER`; introspection (`generate-schema`)
  can't distinguish it from a plain integer, so a generated boolean-ish column
  comes back as `int` (`active` in the example app). You can still use
  `BooleanSqlType()` when you hand-write or adjust the schema.
- `DateTime` is stored as `INTEGER` epoch milliseconds by `DateTimeSqlType()`.

`SqliteDialect.encodeParam` maps canonical Dart values to driver form:
`bool`→`int`, `DateTime`→epoch-ms. Decoders in `SqlType` are lenient and
accept either representation.

## Cross-backend portability

The canonical introspection model (`ColumnType { integer, text, real, boolean,
blob, dateTime }`) maps these uniformly. Postgres — which has native
`bool`/`timestamp` — yields `bool` / `DateTime` directly from introspection.
Application code written against `Connection` and the query DSL runs unchanged
on either backend; only the on-disk representation and introspection output
differ.

## Custom types

Custom `SqlType` codecs work the same as on any backend — see `basalt`
**Types**. `generate-schema` emits built-in types by default; to have it emit a
custom `SqlType` instead of editing the generated schema by hand, configure a
`types:` override in `basalt.yaml` (by specific column, native type, or
canonical type) — see `basalt_cli` **Getting Started**.
