# Migration Commands

The `basalt` CLI (`package:basalt_cli`) wraps the core migration engine from
`package:basalt/migration.dart` with filesystem scaffolding and command-line
commands. Run it from a directory containing `basalt.yaml`:

```sh
dart run basalt_cli:basalt <command>
```

For the engine API (`MigrationRunner`, `MigrationSource`, tracking table), see
`packages/basalt/doc/migrations.md`.

## Configuration

`BasaltConfig` resolves the database from `DATABASE_URL` (environment, takes
precedence) with `basalt.yaml` as a fallback:

```yaml
# basalt.yaml
database_url: app.db        # SQLite path; sqlite:/sqlite://file: schemes are stripped
migrations_dir: migrations  # default: migrations
schema_output: lib/schema.dart
```

The backend is chosen by URL scheme in `ConnectionFactory`: `postgres://` /
`postgresql://` open Postgres; anything else is a SQLite path.

## Commands

| Command | Effect |
|---|---|
| `setup` | Create the migrations directory and database, then run pending migrations. |
| `migration generate <name>` | Scaffold `migrations/<version>_<name>/{up,down}.sql`. |
| `migration run` | Apply all pending migrations (each in a transaction). |
| `migration revert` | Run the most recent migration's `down.sql` and forget its version. |
| `migration redo` | Revert then re-apply the most recent migration. |
| `migration list` | Show applied vs pending migrations. |
| `database reset` | Drop/recreate and re-apply (fresh database; SQLite only today). |
| `generate-schema` | Introspect the database into a typed Dart schema (`schema_output`). |

## Typical workflow

```sh
dart run basalt_cli:basalt migration generate create_users
# edit migrations/<version>_create_users/up.sql and down.sql

dart run basalt_cli:basalt migration run
dart run basalt_cli:basalt generate-schema
```

## Embedding from disk

`basalt_cli` re-exports `package:basalt/migration.dart` and adds
`DirectoryMigrationSource` for on-disk discovery:

```dart
import 'package:basalt_cli/basalt_cli.dart';

final runner = MigrationRunner(
  connection,
  DirectoryMigrationSource('migrations'),
);
await runner.runPending();
```

For Flutter apps that bundle migration SQL as assets, implement
`MigrationSource` against `AssetManifest` (see the example app's
`AssetMigrationSource`).
