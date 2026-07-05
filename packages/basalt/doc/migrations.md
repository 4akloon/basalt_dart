# Migrations

`package:basalt/migration.dart` is the driver-agnostic migration engine. It
applies versioned SQL files against any `Connection`, tracks applied versions
in `__basalt_schema_migrations`, and supports revert via optional `down` SQL.

Import it separately from the main ORM library:

```dart
import 'package:basalt/migration.dart';
```

## Migration layout

```
migrations/
  2024-01-15-123456_create_users/
    up.sql      -- applied by [MigrationRunner.runPending]
    down.sql    -- applied by [MigrationRunner.revertLast] (optional)
```

The directory name is `<version>_<name>`. The **version** is the part before
the first `_`; migrations are ordered lexicographically by version
(zero-padded timestamps sort correctly).

`up.sql` / `down.sql` are executed as raw multi-statement SQL via
`Connection.executeSql`. Each apply or revert is wrapped in a transaction
together with the tracker-table change.

## Tracking table

Applied versions are recorded in `__basalt_schema_migrations`:

```sql
CREATE TABLE IF NOT EXISTS __basalt_schema_migrations
  (version VARCHAR(50) PRIMARY KEY NOT NULL,
   run_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
```

The engine reads and writes this table through the typed query builder (it
dogfoods the ORM). `run_on` is written as UTC `YYYY-MM-DD HH:MM:SS`.

## MigrationSource

`MigrationRunner` needs a `MigrationSource` that supplies migrations with SQL
already resolved. Implementations vary by environment:

| Source | Package | Reads from |
|---|---|---|
| `DirectoryMigrationSource` | `basalt_cli` | On-disk `migrations/` tree (`dart:io`) |
| `AssetMigrationSource` | your app | Flutter `AssetManifest` (bundled assets) |
| custom | your code | any store |

```dart
final runner = MigrationRunner(connection, DirectoryMigrationSource('migrations'));

await runner.runPending();           // apply all pending
final status = await runner.status(); // (applied: [...], pending: [...])
await runner.revertLast();           // undo the most recent
```

## CLI workflow

The `basalt` CLI (`package:basalt_cli`) scaffolds migration files on disk and
runs the same engine via `DirectoryMigrationSource`. See
`packages/basalt_cli/doc/migrations.md` for command reference (`migration
generate`, `migration run`, `generate-schema`, etc.).

## Conventions

- **Version format** — the CLI scaffolder emits `%Y-%m-%d-%H%M%S`
  (e.g. `2024-01-15-123456`); numeric prefixes like `0001` also work.
- **Revert without `down.sql`** — the tracker row is still removed; schema
  changes are not rolled back.
- **Eager loading** — `MigrationSource.discover` resolves all SQL up front;
  fine for typical single-digit migration sets.
