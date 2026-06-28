# diesel_example

End-to-end tour of diesel_dart: apply SQL migrations with the `diesel_dart`
CLI, generate typed readers/queries from annotations, then run the full query
surface through the ORM.

## Layout

- `diesel.yaml` — CLI config (`database_url: example.db`, `migrations_dir: migrations`).
- `migrations/` — `<timestamp>_<name>/{up,down}.sql`. Creates `users` and `posts`,
  and adds a self-referential `users.manager_id` foreign key.
- `lib/schema.dart` — **generated** by `diesel_dart print-schema` (tables/columns only).
- `lib/user.dart`, `lib/post.dart` — hand-written data classes. `User` carries
  `@Queryable` + `@Insertable` + `@AsChangeset`; both use `@Relation` for joins.
- `lib/user.g.dart`, `lib/post.g.dart` — **generated** by `diesel_codegen` (`build_runner`).
- `bin/example.dart` — seeds via `toInsert()`, mutates via `toUpdate()`, and exercises the query surface.

## What the codegen emits

- `@Queryable(table)` → a composable, alias-parameterized row reader `$XFromRow`,
  a reusable `xMapper` (`RowMapper<X>`), and — when the class has `@Relation`s —
  a **self-mapping join query** getter (e.g. `userQuery`/`postQuery`) that wires
  up the joins, table aliases and nested decoding for you, and is still a
  chainable `MappedQuery`.
- `@Insertable(table)` → a `toInsert()` extension returning an `InsertStatement`.
- `@AsChangeset(table)` → a `toUpdate()` extension returning an `UpdateStatement`
  (the `SET` clause; you append the `.where(...)`).

Fields map to columns by name (camelCase ↔ snake_case). Override or tune a field
with `@Column(SomeTable.col, readOnly: …, writeOnly: …)`: `readOnly` is read on
SELECT but skipped on write (autoincrement PKs, server defaults); `writeOnly` is
written but skipped by the row reader.

`@Relation(fk, depth: n)` unrolls the join `n` levels deep with path-based
aliases (`author`, `author_manager`, …), so even self-referential and cyclic
relations are safe. Relation fields must be nullable and optional, and are
skipped by the write derives.

## Run (from this directory)

```sh
# 1. Apply migrations — creates example.db (users/posts + manager_id).
dart run diesel_cli:diesel_dart database reset   # or: migration run

# 2. (Re)generate the typed schema from the migrated database.
dart run diesel_cli:diesel_dart print-schema -o lib/schema.dart

# 3. Generate row readers / query getters from the annotations.
dart run build_runner build

# 4. Run the demo.
dart run bin/example.dart
```

> Note: SQLite has no native boolean, so `users.active` is an `int` column.

Expected output:

```
=== Generated self-mapping join queries ===
Posts with author + author.manager (most viewed first):
  Post("Hello", 150 views, by Bob (mgr: Carol))
  Post("World", 90 views, by Dave (mgr: Bob))
  Post("Untitled", 5 views, by Carol)

Active users that report to someone:
  User(#1 Bob, age 30, reports to Carol)

=== Single-table queries & the predicate DSL ===
Active users older than 28: [Carol, Bob]
Users whose name contains "a": [Carol, Dave]
Two youngest aged 26..45: [Bob, Carol]
Top managers (no manager_id): [Carol]

=== Manual joins & projection control ===
Every post with its author (leftJoin): [Hello <- Bob, World <- Dave, Untitled <- Carol]
Popular post titles (>=90 views): [Hello (150), World (90)]
Reporting lines (name -> manager): [Bob -> Carol, Dave -> Bob]

=== Writes (UPDATE / DELETE) ===
Reactivated 1 user(s).
Deleted 1 low-traffic post(s).
Remaining posts: [Hello, World]

=== Raw SQL escape hatches ===
Active users: 3, average age: 32.333333333333336
After raw birthday bump: User(#1 Bob, age 31)
```

Other CLI commands: `migration generate <name>`, `migration list`,
`migration revert`, `migration redo`, `database reset`.
