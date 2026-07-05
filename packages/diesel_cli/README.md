# diesel_cli

![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5-0175C2?logo=dart&logoColor=white)
![Executable](https://img.shields.io/badge/executable-diesel__dart-blue)
![Part of](https://img.shields.io/badge/part_of-diesel__dart-informational)

**The `diesel_dart` command-line tool for [diesel_dart](../../README.md)** — migrations and schema
generation. The executable is deliberately named `diesel_dart` (distinct from the Rust `diesel`), yet on
SQLite it shares the migrations directory and tracking table with the Rust CLI.

```sh
dart run diesel_cli:diesel_dart <command>
```

Run it from a directory containing a `diesel.yaml` (or with `DATABASE_URL` set).

## Contents

- [Install](#install)
- [Configuration](#configuration)
- [Commands](#commands)
- [The migration workflow](#the-migration-workflow)
- [Migration tracking & diesel-rs compatibility](#migration-tracking--diesel-rs-compatibility)
- [Library use](#library-use)

## Install

```yaml
dev_dependencies:
  diesel_cli:
```

## Configuration

```yaml
# diesel.yaml
database_url: app.db        # SQLite path; the DATABASE_URL env var overrides this
migrations_dir: migrations  # default: migrations
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
| `print-schema [-o <file>]` | Introspect the DB into a typed Dart schema (stdout or `-o` file). |

## The migration workflow

```sh
# 1. Scaffold a versioned migration and edit its up.sql / down.sql.
dart run diesel_cli:diesel_dart migration generate create_users

# 2. Apply pending migrations.
dart run diesel_cli:diesel_dart migration run

# 3. Regenerate the typed schema after any schema change.
dart run diesel_cli:diesel_dart print-schema -o lib/schema.dart
```

A migration is a directory `migrations/<version>_<name>/` with `up.sql` (apply) and `down.sql` (revert);
versions use diesel-rs's `%Y-%m-%d-%H%M%S` format and order the run. Full guide:
[docs/migrations.md](../../docs/migrations.md).

## Migration tracking & diesel-rs compatibility

Applied versions live in `__diesel_schema_migrations` (`version VARCHAR(50)` primary key,
`run_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP`) — matching the Rust `diesel` CLI exactly. On SQLite the
migrations directory and tracker table are **interchangeable with the Rust `diesel` CLI**: migrations
authored by one tool apply cleanly under the other.

## Library use

The package also exports its engine so you can embed migrations in tests or app startup:

- `MigrationRunner` — apply/revert against any `Connection`.
- `DieselConfig` — parse `diesel.yaml` / `DATABASE_URL`.
- `ConnectionFactory` — open the right backend from a `database_url`.
- `SchemaGenerator` — the `print-schema` engine.
- `MigrationScaffolder` — the `migration generate` engine.
- `CliRunner` — the whole command dispatcher.

```dart
import 'package:diesel_cli/diesel_cli.dart';

await MigrationRunner(connection, 'migrations').runPending(); // apply pending in code
```
