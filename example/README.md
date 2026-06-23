# diesel_example

End-to-end demo of the migration-first workflow: apply SQL migrations with the
`diesel_dart` CLI, then run typed queries through the ORM.

## Layout

- `diesel.yaml` — CLI config (`database_url: example.db`, `migrations_dir: migrations`).
- `migrations/` — `<timestamp>_<name>/{up,down}.sql` (creates `users` and `posts`).
- `lib/schema.dart` — **generated** by `diesel_dart print-schema` (tables/columns only).
- `lib/models.dart` — **hand-written** data classes + row readers over that schema.
- `bin/example.dart` — seeds data and runs a typed join.

## Run (from this directory)

```sh
# 1. Apply migrations — creates example.db with the users/posts tables.
dart run diesel_cli:diesel_dart setup        # or: migration run

# 2. (Re)generate the typed schema from the migrated database.
dart run diesel_cli:diesel_dart print-schema -o lib/schema.dart

# 3. Inspect migration status.
dart run diesel_cli:diesel_dart migration list

# 4. Run the typed-query demo.
dart run bin/example.dart
```

> Note: SQLite has no native boolean, so the generated `users.active` is an
> `int` column — `lib/models.dart` reflects that. Data-class generation
> (`@Queryable`) is a later stage; for now models are hand-written.

Expected output:

```
Posts with authors:
  Post("Hello", 150 views, by Bob)
  Post("World", 90 views, by Carol)
```

Other CLI commands: `migration generate <name>`, `migration revert`,
`migration redo`, `database reset`.
