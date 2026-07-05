# basalt_cli

![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5-0175C2?logo=dart&logoColor=white)
![Executable](https://img.shields.io/badge/executable-basalt-blue)
![Part of](https://img.shields.io/badge/part_of-basalt__dart-informational)

**The `basalt` command-line tool for [basalt_dart](../../README.md)** — migrations and schema
generation.

```sh
dart run basalt_cli:basalt <command>
```

Run it from a directory containing a `basalt.yaml` (or with `DATABASE_URL` set). Use `--config/-c`
to point at a non-default config file.

## Contents

- [Install](#install)
- [Configuration](#configuration)
- [Commands](#commands)
- [The migration workflow](#the-migration-workflow)
- [Migration tracking & basalt compatibility](#migration-tracking--basalt-compatibility)
- [Library use](#library-use)

## Install

```yaml
dev_dependencies:
  basalt_cli:
```

## Configuration

```yaml
# basalt.yaml
database_url: app.db        # SQLite path; the DATABASE_URL env var overrides this
migrations_dir: migrations  # default: migrations
schema_output: lib/schema.dart  # default: lib/schema.dart
```

The backend is chosen by URL scheme (`ConnectionFactory`): `postgres://` / `postgresql://` use the Postgres
backend (`postgres://user:pass@host:5432/db?sslmode=disable`); anything else is treated as a SQLite path.

## Commands

| Command | Effect |
|---|---|
| `setup` | Create the migrations directory + database and run pending migrations. |
| `migration generate <name>` | Scaffold `migrations/<version>_<name>/{up,down}.sql`. |
| `migration run` | Apply pending migrations (each in a transaction). |
| `migration revert` | Run the latest migration's `down.sql`. |
| `migration redo` | Revert then re-apply the latest migration. |
| `migration list` | Show applied vs pending. |
| `database reset` | Recreate the database from scratch. |
| `generate-schema` | Introspect the DB into a typed Dart schema (`schema_output` in config). |

## The migration workflow

```sh
# 1. Scaffold a versioned migration and edit its up.sql / down.sql.
dart run basalt_cli:basalt migration generate create_users

# 2. Apply pending migrations.
dart run basalt_cli:basalt migration run

# 3. Regenerate the typed schema after any schema change.
dart run basalt_cli:basalt generate-schema
```

A migration is a directory `migrations/<version>_<name>/` with `up.sql` (apply) and `down.sql` (revert);
versions use basalt's `%Y-%m-%d-%H%M%S` format and order the run. Full guide:
[packages/basalt_cli/doc/migrations.md](doc/migrations.md).

## Migration tracking & basalt compatibility

Applied versions live in `__basalt_schema_migrations` (`version VARCHAR(50)` primary key,
`run_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP`).

## Library use

The package also exports the migration engine and CLI helpers:

- `MigrationRunner` / `MigrationSource` — from `package:basalt/migration.dart` (re-exported).
- `DirectoryMigrationSource` — on-disk migration discovery (`dart:io`).
- `BasaltConfig` — parse `basalt.yaml` / `DATABASE_URL`.
- `ConnectionFactory` — open the right backend from a `database_url`.
- `SchemaGenerator` — the `generate-schema` engine.
- `MigrationScaffolder` — the `migration generate` engine.
- `CliRunner` — the whole command dispatcher.

```dart
import 'package:basalt_cli/basalt_cli.dart';

await MigrationRunner(
  connection,
  DirectoryMigrationSource('migrations'),
).runPending();
```
