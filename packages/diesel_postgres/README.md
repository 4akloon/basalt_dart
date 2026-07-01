# diesel_postgres

The **Postgres backend** for [diesel_dart](../../README.md). Work in progress.

## Status

- ✅ `PostgresDialect` — numbered `$N` placeholders (1-based) and double-quoted identifiers. Paired with the core
  `QueryBuilder`, it serializes Postgres-flavored SQL (proof that the builder is backend-agnostic):

  ```dart
  final (sql, params) = QueryBuilder(const PostgresDialect()).buildSelect(query);
  // ... WHERE ("users"."age" > $1) ...
  ```
- ⬜ Driver-backed `PostgresConnection` (on `package:postgres`) implementing the same `Connection` interface as
  `SqliteConnection` — requires a live Postgres to complete/verify.
- ⬜ Postgres introspection (`information_schema` / `pg_catalog`) for `diesel_dart print-schema`.
- ⬜ PG types (`timestamptz`, `uuid`, `json`/`jsonb`, `numeric`, arrays).

See the [roadmap](../../docs/ROADMAP.md).
