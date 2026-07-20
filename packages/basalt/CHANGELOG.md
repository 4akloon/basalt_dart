# Changelog

## 0.0.3

Shared DevTools inspector client — one host + client + DTO layer behind the
`ext.basalt.*` protocol, so the DevTools extension and the `basalt_mcp` server
stop re-implementing it.

- New `package:basalt/devtools_client.dart` entrypoint (kept separate from the
  host `package:basalt/devtools.dart`): a transport-agnostic `InspectorClient`
  plus an `InspectorTransport` seam and the shared DTOs. Consumers implement
  only the transport (VM service, DevTools `serviceManager`, ...).
- `BasaltExtension` — enum of the `ext.basalt.*` method names, the single source
  of truth for host registration and every client (exported from both
  entrypoints).
- DTO `fromJson` factories now parse real `jsonDecode` output (previously the
  blind `as List<...>` casts threw); `SqlResultDto.fromJson` restores
  `truncated`; `RegisteredInstance.fromJson` added.
- **Breaking (dev-only):** `RegisteredInstance.backend` removed — the inspector
  no longer infers a backend name. `InspectorService` now takes placeholders,
  identifier quoting, and value encoding from `Connection.dialect` (this also
  fixes `DateTime` encoding on the raw-SQL path). `lib/src/devtools/` was
  reorganized into `protocol/` · `dto/` · `host/` · `client/` (internal), and
  `InspectorService` was split into focused collaborators.

## 0.0.2

Single-statement batch writes.

- `updateAll(table).keyedBy(col).values([...])` — a new `UpdateAllStatement` that updates many
  rows with per-row values in one statement (`WITH ... AS (VALUES ...) UPDATE ... FROM`), with
  composite keys (repeated `keyedBy`), an optional extra `.where(...)`, and `RETURNING` support
  (columns are table-qualified there to stay unambiguous next to the `VALUES` table).
- `SqlDialect.castType(SqlType)` — new dialect seam naming the native type to `CAST` a bound
  parameter to where SQL gives the server no inference context (the `VALUES` table of
  `updateAll`); dialects that don't need casts return `null`.
- `ColumnValue` now carries the column's `SqlType` (set by `TableColumn.set`) so serialization
  can emit those casts.
- A zero-row `INSERT` (no `.value(...)`/`.values(...)`) now throws `StateError` at build time
  instead of emitting invalid SQL.
- `@Insertable` doc updated for the new generated batch extension (see `basalt_codegen` 0.0.2).

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
