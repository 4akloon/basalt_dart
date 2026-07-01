# diesel_cli

The **`diesel_dart` command-line tool** for [diesel_dart](../../README.md): migrations and schema generation.
The executable is named `diesel_dart` (deliberately distinct from the Rust `diesel`).

```sh
dart run diesel_cli:diesel_dart <command>
```

Run it from a directory containing a `diesel.yaml` (or with `DATABASE_URL` set).

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

## Configuration

```yaml
# diesel.yaml
database_url: app.db        # SQLite path; DATABASE_URL env overrides this
migrations_dir: migrations  # default: migrations
```

The backend is selected by URL scheme (`ConnectionFactory`): `postgres://` / `postgresql://` use the Postgres
backend (`postgres://user:pass@host:5432/db?sslmode=disable`); anything else is a SQLite path.

## Migration tracking

Applied versions live in `__diesel_schema_migrations` (`version VARCHAR(50) PK`,
`run_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP`) — matching the Rust `diesel` CLI. Migrations are ordered by the
version prefix of each directory name.

On SQLite the migrations directory and tracker table are interchangeable with the Rust `diesel` CLI; see the
[migrations guide](../../docs/migrations.md) and [ROADMAP M1](../../docs/ROADMAP.md).

## Library use

The package also exports the engine for embedding/testing: `MigrationRunner` (works against any `Connection`),
`DieselConfig`, `ConnectionFactory`, `SchemaGenerator`, `MigrationScaffolder`, and `CliRunner`.
