# Changelog

## 0.0.1

Initial development release of the basalt_dart `build_runner` code generator.

- `@Queryable` — generates a `RowReader`-based mapper and typed query getters.
- `@Insertable` — generates a `toInsert()` builder.
- `@AsChangeset` — generates a `toChangeset()` builder for `UPDATE`.
- `@Relation` — generates self-mapping join queries (has-many folds, ref joins).
- Pure, unit-tested emitters bridged by thin `GeneratorForAnnotation` classes, registered in a
  single `SharedPartBuilder`.
