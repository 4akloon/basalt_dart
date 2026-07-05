# Contributing to basalt_dart

Thanks for helping build basalt_dart! This guide covers everything about *developing the project itself* —
setup, day-to-day commands, the architecture, how to extend it, and the conventions to follow. The package
READMEs stay user-facing; this file (and [CLAUDE.md](CLAUDE.md), the exhaustive repo guide) is for
contributors.

## Contents

- [Prerequisites](#prerequisites)
- [Getting the code](#getting-the-code)
- [Repository layout](#repository-layout)
- [Everyday commands](#everyday-commands)
- [Architecture at a glance](#architecture-at-a-glance)
- [Extending the project](#extending-the-project)
- [The DevTools extension](#the-devtools-extension)
- [Coding conventions](#coding-conventions)
- [Tests](#tests)
- [Commits & pull requests](#commits--pull-requests)

## Prerequisites

- **Dart SDK `>=3.5.0 <4.0.0`** — the whole workspace targets this range.
- **Flutter** (stable) — only to build the DevTools UI in
  [`packages/basalt_devtools_extension`](packages/basalt_devtools_extension).
- **Docker** — only to run the `basalt_postgres` integration tests (a throwaway Postgres).

## Getting the code

This repo is a **Dart pub workspace** (monorepo): one `dart pub get` at the root resolves every member
together against a single lockfile.

```sh
git clone <repo> basalt_dart && cd basalt_dart
dart pub get
```

The Flutter UI package is intentionally **not** a workspace member (it needs the Flutter SDK), so resolve it
separately when you touch it: `cd packages/basalt_devtools_extension && flutter pub get`.

## Repository layout

See the [packages table in the root README](README.md#packages) for what each package does. Key points for
contributors:

- Core lives in `packages/basalt` and has **no driver dependency**; backends depend on it.
- `packages/basalt_devtools_extension` is a Flutter app **outside** the workspace; its compiled output is
  copied into `packages/basalt/extension/devtools/build/` (git-ignored).
- `example/` is the end-to-end demo *and* hosts the DevTools inspector demo/launcher (`example/tool/`).

## Everyday commands

```sh
# Analyze every package + the example.
dart analyze packages example

# Test one package.
cd packages/<pkg> && dart test

# Test them all.
for p in basalt basalt_sqlite basalt_cli basalt_codegen basalt_postgres; do
  (cd packages/$p && dart test); done

# End-to-end: regenerate codegen + run the demo.
cd example && dart run build_runner build && dart run bin/example.dart

# Format (line length 80, project default).
dart format .
```

**Postgres tests** need a server; the suite skips gracefully if none is reachable:

```sh
docker run -d --name basalt_pg \
  -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=basalt_test -p 5433:5432 postgres:16
cd packages/basalt_postgres && dart test        # override via BASALT_PG_HOST / BASALT_PG_PORT
```

**The CLI** (run from a dir with a `basalt.yaml`, e.g. `example/`):
`dart run basalt_cli:basalt <command>` — `setup`, `migration generate/run/revert/redo/list`,
`database reset`, `generate-schema`. Global `--config/-c` selects a non-default `basalt.yaml`.

## Architecture at a glance

- **Build vs execute (the core principle).** The query builder is a *pure* transform of a typed AST into
  `(String sql, List<Object?> params)` — `QueryBuilder` + `SqlDialect`, zero driver dependency. A
  `Connection` serializes and runs the result. This keeps serialization unit-testable and makes new backends
  drop-in.
- **Typed schema.** Columns are `static const` `TableColumn<T, Tbl>` (sealed: `ValueColumn` / `PrimaryKey` /
  `Ref`) on `abstract final class` markers, so the same object is used by the builder and by annotations.
- **Two-tier join safety.** `from(t)` is compile-time scoped to `Tbl`; after a join the scope relaxes to
  `Object?` and the serializer validates every referenced table is in the FROM/JOIN clause.
- **Codegen pipeline.** `EdgeAnalyzer` (analyzer elements → a plain model) → **pure string emitters**
  (`reader_emitter` / `insert_emitter` / `changeset_emitter` / relation emitters) → thin
  `GeneratorForAnnotation` bridges, all wired into a `SharedPartBuilder` in `builder.dart`.

The file map ("where things live") is in [CLAUDE.md](CLAUDE.md).

## Extending the project

- **New backend:** implement `Connection` + `SqlDialect` + `introspect()` in a new `basalt_<db>` package,
  then wire it into `ConnectionFactory.open` (in `basalt_cli`) by URL scheme. No core/command changes.
- **New annotation / derive:** add the annotation in `packages/basalt/lib/src/annotations/`, a `TypeChecker`
  + parsing in `edge_analyzer.dart`, a pure emitter, a `GeneratorForAnnotation` (see `write_generator.dart`),
  and register it in `builder.dart`'s `SharedPartBuilder`. Keep emitters pure and unit-tested.
- **New CLI command:** add a `Command` under `basalt_cli/lib/src/commands/` (extend `DbCommand` for
  DB-connected ones) and register it in `CliRunner.build()`.

## The DevTools extension

The inspector runtime lives in core (`package:basalt/devtools.dart`; `packages/basalt/lib/src/devtools/`).
The UI is the Flutter app in `packages/basalt_devtools_extension`. After changing the UI, rebuild the
git-ignored web bundle into the `basalt` package:

```sh
cd packages/basalt_devtools_extension
flutter pub get
dart run devtools_extensions build_and_copy --source=. --dest=../basalt/extension/devtools
dart run devtools_extensions validate --package=../basalt
```

Try it end-to-end with the launcher (starts a Dart Tooling Daemon + a seeded app + DevTools):
`dart run example/tool/inspect.dart`, then enable **basalt** in DevTools' Extensions menu. Unit tests for the
runtime live in `packages/basalt_sqlite/test/inspector_test.dart`.

## Coding conventions

- **One class per file; sealed hierarchies use `part`s.** A `sealed` tree (`SqlNode` / `TableColumn` /
  `WriteStatement`) is a `library;` entry file holding the base + `part` directives (imports centralized
  there), with each variant a one-class `part of` file under a subdir. Add a variant = new `part` file + a
  `part` line in the entry.
- **`Connection` is async-first** — every method returns `Future`; `FutureOr` only on the `transaction`
  callback.
- **Columns are `static const`** on `abstract final class` markers (annotation args must be const).
- **Avoid `!`** — prefer `if (x case final y?)` / pattern matching for null handling.
- **Gotcha:** chained `.where().where()` *replaces* the predicate (last wins) — combine with `&`/`|`, or use
  `.filter()` (ANDs). Don't "fix" this by accident.
- **Match the surrounding code** — comment density, naming, and idioms. The full invariant list is in
  [CLAUDE.md](CLAUDE.md).

## Tests

Prefer fast, pure unit tests; the architecture is built for them.

- Serializer (SQL/params, scope validation, joins): `packages/basalt/test/serializer_test.dart`.
- SQLite round-trips, joins, transactions, nullables: `packages/basalt_sqlite/test/`.
- Migrations + generate-schema/introspection: `packages/basalt_cli/test/`.
- Codegen **emitters** (pure, no analyzer) + generate goldens + relation tree: `packages/basalt_codegen/test/`.
- End-to-end: `example/` (`build_runner build`, then `dart run bin/example.dart`).

New behaviour should come with a test at the lowest layer that can cover it (usually a pure emitter or the
serializer).

## Commits & pull requests

- Branch off `main`; don't commit directly to it.
- Run `dart analyze packages example` and the relevant `dart test` suites before pushing.
- Keep commits focused; write a clear subject + a body explaining the *why*.
- Update docs/READMEs when you change user-facing behaviour, and add a `CHANGELOG.md` entry for the affected
  package.
