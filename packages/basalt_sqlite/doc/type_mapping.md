# Type Mapping (SQLite)

SQLite-specific caveats on top of the core codec model in `basalt` **Types**.

## No native boolean or timestamp

SQLite has no native boolean or timestamp type. As a result:

- A `bool` column is typically declared `INTEGER` and stored as `0`/`1`;
  `DateTime` is stored as `INTEGER` epoch milliseconds by `DateTimeSqlType()`.
- Introspection can't distinguish a bare `INTEGER` from a boolean or a
  timestamp, so such columns generate as `int` (`active` in the example app).

`SqliteDialect.encodeParam` maps canonical Dart values to driver form:
`bool`→`int`, `DateTime`→epoch-ms. Decoders in `SqlType` are lenient and
accept either representation.

### The declared-type preset

The declared column type *does* survive introspection (in `rawType`), so
`SqliteAdapter`'s always-on `generate-schema` preset restores fidelity for
columns you declare explicitly: `BOOLEAN`/`BOOL` emit `bool`
(`BooleanSqlType`), `DATETIME`/`TIMESTAMP` emit `DateTime` (`DateTimeSqlType`)
— nullable columns get the `NullableSqlType(...)` wrapping. The preset uses
core types only, so the generated schema stays backend-portable; declare your
migrations with `BOOLEAN`/`DATETIME` (SQLite treats them as `INTEGER` affinity
anyway) to opt in. A user `types:` override in `basalt.yaml` always wins over
the preset.

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
