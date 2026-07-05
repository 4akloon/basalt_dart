# CLAUDE.md

Guidance for Claude Code (and humans) working in this repository.

## What this is

**basalt_dart** is a type-safe ORM for Dart.
It is a Dart **pub workspace** (monorepo) with a dialect-agnostic core and pluggable backends. Current
backend: SQLite. Status: early/experimental, unpublished (all packages `0.0.1`, path/workspace deps).

## Core principle

**Build vs execute separation.** The query builder is a pure transformation of a typed AST into
`(String sql, List<Object?> params)` (`QueryBuilder` + `SqlDialect`), with zero driver dependency. A
`Connection` implementation serializes and runs the result against a real driver. This keeps serialization
trivially unit-testable and makes new backends drop-in.

## Workspace layout

| Path | Package | Role |
|---|---|---|
| `packages/basalt` | `basalt` | Dialect-agnostic core: types, schema, expressions, query/write builders, serializer, `Connection`/`SqlDialect` interfaces, annotations. No driver dep. Also provides the **DevTools inspector runtime** as a separate entrypoint `package:basalt/devtools.dart` (registry + `InspectorService` over `ext.basalt.*`; `lib/src/devtools/`) and ships the DevTools extension (`extension/devtools/`). |
| `packages/basalt_sqlite` | `basalt_sqlite` | SQLite backend: `SqliteConnection` + `SqliteDialect` (on `package:sqlite3`). |
| `packages/basalt_postgres` | `basalt_postgres` | Postgres backend: `PostgresConnection` + `PostgresDialect` (on `package:postgres`), with `information_schema` introspection. |
| `packages/basalt_cli` | `basalt_cli` | `basalt` executable: migrations + `generate-schema`. |
| `packages/basalt_codegen` | `basalt_codegen` | `build_runner`/`source_gen` derives for the annotations. |
| `packages/basalt_devtools_extension` | `basalt_devtools_extension` | Flutter web UI for the DevTools "basalt" tab. Under `packages/` but **not** a Dart-workspace member (Flutter app; resolve with `flutter pub get`); compiled into `basalt/extension/devtools/build/`. |
| `example/` | `basalt_example` | End-to-end demo (migrations → schema → models → queries). |

Dart SDK constraint: `>=3.5.0 <4.0.0`.

## Commands

- **Analyze:** `dart analyze packages/basalt packages/basalt_sqlite packages/basalt_cli packages/basalt_codegen example`
- **Test a package:** `cd packages/<pkg> && dart test`
- **CLI** (run from a directory containing `basalt.yaml`, e.g. `example/`): `dart run basalt_cli:basalt <command>`
  - `setup` · `migration generate <name>` · `migration run` · `migration revert` · `migration redo` ·
    `migration list` · `database reset` · `generate-schema` · `--config <path>`
- **Codegen** (in `example/`): `dart run build_runner build`

## Key invariants & conventions (don't break these)

- **async-first `Connection`** — every method returns `Future`; `FutureOr` only on the `transaction`
  callback. SQLite runs synchronously and returns completed futures; this is what lets a future async backend
  (Postgres) implement the same interface unchanged. (`packages/basalt/lib/src/connection.dart`)
- **Columns are `static const`** on an `abstract final class` table marker — the same `const TableColumn`
  object is used by the query builder AND inside annotations (annotation args must be const).
- **The core column type is `TableColumn<T, Tbl>`** (sealed: `ValueColumn` / `PrimaryKey` / `Ref`). The name
  **`Column` is the field annotation**, not the column type — don't confuse them
  (`schema/table.dart` vs `annotations/column.dart`).
- **Two-tier join safety:** single-table `from(t)` is `Query<Tbl>` (compile-time-scoped `where`); after a
  join it relaxes to `Query<Object?>` and `QueryBuilder._validateScope` validates at build time that every
  referenced table is in the FROM/JOIN clause (`StateError` otherwise).
- **`RowReader` reads by selection key** — columns by `table.name` (alias-aware), aggregates by alias — not
  by position (order-independent, join-safe). The projection is a `List<Selection>` (columns *or* `Aggregate`s);
  the serializer consumes AST-level `Projection`s so it stays schema-free.
- **Codegen pipeline:** `EdgeAnalyzer` (analyzer → model) → pure string emitters
  (`ReaderEmitter` / `InsertEmitter` / `ChangesetEmitter` / relation emitters) → `SharedPartBuilder` with
  **three** generators (`QueryableGenerator`, `InsertableGenerator`, `AsChangesetGenerator`) registered in
  `builder.dart`. Emitters are pure and unit-tested; generators are thin analyzer bridges.
- **GOTCHA: chained `.where().where()` REPLACES the predicate (last wins), it does not AND.** Combine with
  `&` (`q.where(a.eq(1) & b.isNotNull())`), or use `.filter()` — the basalt-style method that ANDs repeated
  calls. (`Query.where` does `_copy(whereNode: ...)`; `filter` ANDs onto the existing `whereNode`.)
- **Avoid `!`** — prefer `if (x case final y?)` / pattern matching for null handling (project style).
- **One class per file; sealed hierarchies use `part`s.** Each class/DTO lives in its own file. A `sealed`
  hierarchy can't span libraries, so its entry file (`sql_node.dart` / `table.dart` / `write.dart`) is a
  `library;` that holds the base + `part` directives and centralizes the imports, and every variant is a
  one-class `part of` file under a subdir (`ast/nodes/` + `ast/clauses/`, `schema/columns/` + `schema/*`,
  `query/writes/`). Add a new variant = new `part` file + a `part` line in the entry.

## Where things live (core, `packages/basalt/lib/src/`)

- Types & codecs: `types/sql_type.dart`
- Schema (`TableColumn`/`PrimaryKey`/`Ref`/`TableRef`/`QuerySource`/`TableAlias`): `schema/table.dart`
- Expressions + `&`/`|` combinators: `expression/expression.dart`
- Query builder + `RowReader` + `RowMapper`: `query/query.dart`, `query/row_reader.dart`
- Writes (`insertInto`/`update`/`deleteFrom` + `TableColumn.set`): `query/write.dart`
- AST nodes: `ast/sql_node.dart`
- Serializer + scope validation: `serialize/query_builder.dart`; dialect seam: `serialize/sql_dialect.dart`
- `Connection`: `connection.dart`; introspection model: `schema/introspection.dart`
- Annotations: `annotations/{queryable,insertable,as_changeset,column,relation}.dart`

## How to extend

- **New backend:** implement `Connection` + `SqlDialect` + `introspect()` in a new `basalt_<db>` package,
  then wire it into `ConnectionFactory.open` by URL scheme. No command/core changes needed.
- **New annotation/derive:** add the annotation in `packages/basalt/lib/src/annotations/`, a `TypeChecker` +
  parsing in `edge_analyzer.dart`, a pure emitter, a `GeneratorForAnnotation` (see `write_generator.dart`),
  and register it in `builder.dart`'s `SharedPartBuilder`.
- **New CLI command:** add a `Command` under `basalt_cli/lib/src/commands/` (extend `DbCommand` for
  DB-connected commands) and register it in `CliRunner.build()`.

## Documentation

No root `docs/` folder. Each package owns its documentation:
`packages/<pkg>/dartdoc_options.yaml` (categories) + `packages/<pkg>/doc/*.md` (one markdown guide
per category) + `///` doc comments in `lib/`.

| Package | Guides (`doc/`) |
|---|---|
| `basalt` | getting_started, schema, types, expressions, queries, writes, serialization, connection, annotations |
| `basalt_cli` | getting_started, migrations |
| `basalt_codegen` | getting_started |
| `basalt_sqlite` | getting_started, type_mapping |
| `basalt_postgres` | getting_started |

Generate HTML locally: `cd packages/<pkg> && dart doc .` (output in `doc/api/`, gitignored).

- Every public class/top-level function/member gets a `///` doc comment: first line is a one-sentence
  summary, further paragraphs add detail.
- Cite other symbols with `[Symbol]` only when linking within the **same** package/library scope
  (dartdoc resolves these). In `doc/*.md` guide files, and whenever referencing another package's types,
  use plain `` `Symbol` `` code spans instead — bracket refs in category markdown don't resolve across
  packages/files and emit `unresolved doc reference` warnings.
- When adding a new public class/top-level declaration, tag it with the matching `{@category some-category}`
  from that package's `dartdoc_options.yaml`. Don't leave new public API untagged. Prefer an existing
  category; only add a new one (+ a new `doc/<name>.md`) for a genuinely new topic area.
- Guides are example-driven: short runnable snippets, not prose-only.
- **`displayName` must produce a filename distinct from the category slug** (e.g. slug
  `schema` + displayName `Schema & Columns`, not `Schema`). On macOS's case-insensitive
  filesystem, `Schema-topic.html` and `schema-topic.html` collide — dartdoc overwrites the
  real page with a self-redirect stub and the topic appears blank.
- After doc changes, run `dart doc .` from the package directory and fix any warnings. Never commit
  generated `doc/api/`.

## Test map

- Serializer (SQL/params, scope validation, joins): `packages/basalt/test/serializer_test.dart`
- SQLite round-trips, joins, transactions, nullable: `packages/basalt_sqlite/test/integration_test.dart`
- Migrations + generate-schema/introspection: `packages/basalt_cli/test/{migrations_test,generate_schema_test}.dart`
- Codegen emitters + generate + relation tree: `packages/basalt_codegen/test/*`
- End-to-end: `example/` (`dart run build_runner build`, then `dart run bin/example.dart`)

## Design goals

basalt_dart provides a type-safe query builder, CLI, codegen derives, and pluggable
backends — SQLite and Postgres run the same DSL, schema, and migrations unchanged.
Per-package guides live under `packages/<pkg>/doc/`; run `dart doc .` in a package to
browse the generated API docs locally.
