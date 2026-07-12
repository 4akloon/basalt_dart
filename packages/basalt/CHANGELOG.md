# Changelog

## 0.0.1

Initial development release of the basalt_dart core.

- Type system: `SqlType<T>` codecs (`IntSqlType`/`StringSqlType`/`DoubleSqlType`/`BooleanSqlType`/
  `BlobSqlType`/`DateTimeSqlType`) with a single `NullableSqlType(...)` wrapper for nullable columns.
- Schema: sealed `TableColumn<T, Tbl>` (`ValueColumn` / `PrimaryKey` / `Ref`), `TableRef`, `QuerySource`,
  `TableAlias` for self-joins.
- Expressions with phantom table scope; `eq`/`ne`/`gt`/`ge`/`lt`/`le`/`isIn`/`between`/`isNull`/`like`/
  `eqColumn`, operator sugar, and `&`/`|` combinators.
- Query builder: `from().where().orderBy().limit().offset().select().innerJoin()/leftJoin().map()` →
  `MappedQuery`; `RowReader` (read by column name) and reusable `RowMapper`.
- Writes: `insertInto` / `update` / `deleteFrom` with `TableColumn.set`.
- Serializer (`QueryBuilder` + `SqlDialect`) with two-tier join scope validation.
- Async-first `Connection` interface with transactions (nested → SAVEPOINT) and `introspect()`.
- Annotations for codegen: `@Queryable`, `@Insertable`, `@AsChangeset`, `@Column` (`readOnly`/`writeOnly`),
  `@Relation`.
