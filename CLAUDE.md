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
| `packages/basalt` | `basalt` | Dialect-agnostic core: types, schema, expressions, query/write builders, serializer, `Connection`/`SqlDialect` interfaces, annotations. No driver dep. Extra entrypoints: `package:basalt/tooling.dart` (**CLI adapter seam** — `BasaltAdapter` + `SchemaTypeOverrides`/`TypeOverride`; `lib/src/tooling/`) and `package:basalt/devtools.dart` (**DevTools inspector runtime**: registry + `InspectorService` over `ext.basalt.*`; `lib/src/devtools/`); also ships the DevTools extension (`extension/devtools/`). |
| `packages/basalt_sqlite` | `basalt_sqlite` | SQLite backend: `SqliteConnection` + `SqliteDialect` (on `package:sqlite3`) + `SqliteAdapter` (CLI adapter, `lib/adapter.dart`). |
| `packages/basalt_postgres` | `basalt_postgres` | Postgres backend: `PostgresConnection` + `PostgresDialect` (on `package:postgres`), `information_schema` introspection, `PostgresAdapter`/`PostgresEndpoint` (CLI adapter, `lib/adapter.dart`), native `PostgresJsonbSqlType`. |
| `packages/basalt_cli` | `basalt_cli` | `basalt` executable: migrations + `generate-schema`. **Backend-agnostic** — no dep on any backend package; `bin/basalt.dart` bootstraps a generated entrypoint (`.dart_tool/basalt/`) that imports the `backend:` package from `basalt.yaml` (build_runner model). |
| `packages/basalt_codegen` | `basalt_codegen` | `build_runner`/`source_gen` derives for the annotations. |
| `packages/basalt_devtools_extension` | `basalt_devtools_extension` | Flutter web UI for the DevTools "basalt" tab. Under `packages/` but **not** a Dart-workspace member (Flutter app; resolve with `flutter pub get`); compiled into `basalt/extension/devtools/build/`. |
| `example/` | `basalt_example` | End-to-end **Flutter** shop app (products/categories/customers/orders/reviews) with clean architecture + cubit — showcases complex relations, transactions, aggregates and raw-SQL analytics. Like the DevTools extension it is **not** a Dart-workspace member (Flutter app; resolve with `flutter pub get`; uses `dependency_overrides` to point the basalt packages at their local paths). |

Dart SDK constraint: `>=3.5.0 <4.0.0`.

## Commands

- **Analyze:** `dart analyze packages/basalt packages/basalt_sqlite packages/basalt_cli packages/basalt_codegen`
  (the `example/` Flutter app resolves separately — analyze it with `cd example && flutter analyze`).
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
- **`basalt_cli` never imports backend packages.** Backend access goes through `BasaltAdapter`
  (`package:basalt/tooling.dart`): the bootstrapper (`bin/basalt.dart` → `src/bootstrap/`) generates
  `.dart_tool/basalt/entrypoint.dart` importing `package:<backend>/adapter.dart` (top-level `const adapter`
  by convention) and spawns it. The `database:` map from `basalt.yaml` is passed to the adapter **as-is** —
  option keys are adapter-defined, there is no url in the contract. **`backend:` is required — there is no
  default backend** (`BackendResolver`/`BasaltConfig.load` throw if it's absent; a Postgres-looking
  `database.url` only changes the *suggested* value in the error).
- **Nullable column types wrap, they don't duplicate:** `NullableSqlType(XSqlType())` is the only nullable
  variant — never add `*OrNullSqlType` codec copies. In a `SqlType<Object?>`-typed context spell the type
  argument explicitly (`NullableSqlType<int>(...)`) or inference degrades to `<Object>`. **Type overrides
  register the non-nullable base only** — a nullable column derives its variant via `TypeOverride.asNullable`
  (there is no separate nullable registration, no `nullable:` YAML sub-key). Layer sets with
  `SchemaTypeOverrides.overlay` (receiver wins per key); parsing lives in `SchemaTypeOverridesParser`.
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
- CLI adapter seam (`BasaltAdapter`/`SchemaTypeOverrides`/`TypeOverride`): `tooling/` (entrypoint `lib/tooling.dart`)
- Annotations: `annotations/{queryable,insertable,as_changeset,column,relation}.dart`

## How to extend

- **New backend:** in a new `basalt_<db>` package implement `Connection` + `SqlDialect` + `introspect()`,
  plus a `BasaltAdapter` (`open`/`reset` over the raw `database:` options map, optional
  `typeOverrides`/`nativeTypeOverrides` presets for `generate-schema`), and expose
  `lib/adapter.dart` with a top-level `const BasaltAdapter adapter;`. Users select it with
  `backend: basalt_<db>` in `basalt.yaml` — **zero CLI/core changes needed**.
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
| `basalt` | getting_started, schema, types, expressions, queries, writes, serialization, connection, annotations, tooling |
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
- Tooling (preset layering, `NullableSqlType`): `packages/basalt/test/{tooling,types}/*`
- SQLite round-trips, joins, transactions, nullable: `packages/basalt_sqlite/test/integration_test.dart`;
  adapter options/reset/preset: `packages/basalt_sqlite/test/sqlite_adapter_test.dart`
- Postgres endpoint parsing + jsonb codec (no server needed): `packages/basalt_postgres/test/*`
- Migrations + generate-schema/introspection + presets: `packages/basalt_cli/test/{migrations_test,generate_schema_test}.dart`
- Bootstrap (backend resolution, entrypoint codegen, fingerprint, real spawn): `packages/basalt_cli/test/bootstrap_test.dart`
- Codegen emitters + generate + relation tree: `packages/basalt_codegen/test/*`
- End-to-end: `example/` Flutter app (`flutter pub get`, `dart run build_runner build`, then `flutter run`);
  repository-layer tests under `example/test/` run against an in-memory `SqliteConnection`

## Design goals

basalt_dart provides a type-safe query builder, CLI, codegen derives, and pluggable
backends — SQLite and Postgres run the same DSL, schema, and migrations unchanged.
Per-package guides live under `packages/<pkg>/doc/`; run `dart doc .` in a package to
browse the generated API docs locally.
