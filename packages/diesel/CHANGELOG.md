# Changelog

## 0.0.1 (unreleased)

Initial development release of the diesel_dart core.

- Type system: `SqlType<T>` with `integer`/`text`/`real`/`boolean`/`blob`/`dateTime` and `*OrNull` variants.
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
