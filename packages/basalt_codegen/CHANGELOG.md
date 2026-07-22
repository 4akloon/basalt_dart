# Changelog

## 0.1.0

- Table-marker resolution supports the new schema shape where the annotation
  value's type is a non-generic `TableRef` subclass (`@Queryable(Users.table)`
  with `final class Users extends TableRef<Users>`) — the marker is resolved
  from the `TableRef<Tbl>` supertype. Plain `TableRef<X>` values keep working.
- Widened the analyzer constraint to `>=8.0.0 <15.0.0`.
- Requires `basalt >=0.1.0 <0.2.0`.

## 0.0.2

- `@Insertable` now also generates a batch extension on `Iterable` of the annotated class:
  `rows.toInsert()` builds one multi-row `INSERT ... VALUES (...), (...)` (throws
  `ArgumentError` on an empty iterable). Skips `readOnly` columns like the single-row form.
- Requires `basalt >=0.0.2 <0.1.0`.

## 0.0.1

Initial development release of the basalt_dart `build_runner` code generator.

- `@Queryable` — generates a `RowReader`-based mapper and typed query getters.
- `@Insertable` — generates a `toInsert()` builder.
- `@AsChangeset` — generates a `toChangeset()` builder for `UPDATE`.
- `@Relation` — generates self-mapping join queries (has-many folds, ref joins).
- Pure, unit-tested emitters bridged by thin `GeneratorForAnnotation` classes, registered in a
  single `SharedPartBuilder`.
