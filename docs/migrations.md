# Migrations

The `basalt` CLI (package `basalt_cli`) manages a migration-first workflow. Run it from a directory containing `basalt.yaml` (e.g. [`example/`](../example)):

```sh
dart run basalt_cli:basalt <command>
```

## Configuration

`BasaltConfig` resolves the database from `DATABASE_URL` (environment, takes precedence) with `basalt.yaml`
as a fallback, and the migrations directory from `basalt.yaml` (default `migrations`):

```yaml
# basalt.yaml
database_url: app.db        # SQLite path; sqlite:/sqlite://file: schemes are stripped; ':memory:' passes through
migrations_dir: migrations
```

The backend is chosen by URL scheme in `ConnectionFactory`: `postgres://` / `postgresql://` open the Postgres
backend (e.g. `postgres://user:pass@host:5432/db?sslmode=disable`); anything else is a SQLite path.

## Commands

| Command | Effect |
|---|---|
| `setup` | Create the migrations directory and database, then run pending migrations. |
| `migration generate <name>` | Scaffold `migrations/<version>_<name>/{up,down}.sql`. |
| `migration run` | Apply all pending migrations (each in a transaction). |
| `migration revert` | Run the most recent migration's `down.sql` and forget its version. |
| `migration redo` | Revert then re-apply the most recent migration. |
| `migration list` | Show applied vs pending migrations. |
| `database reset` | Drop/recreate and re-apply (fresh database). |
| `generate-schema` | Introspect the database into a typed Dart schema (`schema_output` in `basalt.yaml`). |

## Migration layout

```
migrations/
  2024-01-15-123456_create_users/
    up.sql      -- applied by `migration run`
    down.sql    -- applied by `migration revert`
```

`up.sql` / `down.sql` are executed as raw multi-statement SQL via `Connection.executeSql`. The directory name
is `<version>_<name>`; the **version** is the part before the first `_`, and migrations are ordered
lexicographically by version (zero-padded timestamps sort correctly).

## Tracking table

Applied versions are recorded in `__basalt_schema_migrations`:

```sql
CREATE TABLE IF NOT EXISTS __basalt_schema_migrations
  (version VARCHAR(50) PRIMARY KEY NOT NULL, run_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
```

The `SELECT`/`INSERT`/`DELETE` against this table are built with the query builder itself (the CLI dogfoods
the ORM), and each migration's apply/revert is wrapped in a transaction.

## Migration conventions

basalt_dart uses a consistent migration layout:

- **Directory layout** — `<version>_<name>/{up,down}.sql`; `discover()` reads the dashed version prefix.
- **Version format** — the scaffolder emits `%Y-%m-%d-%H%M%S` (e.g. `2024-01-15-123456`).
- **Tracker DDL** — `version VARCHAR(50) PRIMARY KEY NOT NULL`,
  `run_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`.
- **`run_on`** — written as `YYYY-MM-DD HH:MM:SS`.

## Embedding the runner

The migration engine is exposed for tests/embedding via `package:basalt_cli` (`MigrationRunner`), which works
against any `Connection`:

```dart
final runner = MigrationRunner(connection, 'migrations');
await runner.runPending();
final status = await runner.status();   // (applied: [...], pending: [...])
```
