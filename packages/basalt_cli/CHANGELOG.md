# Changelog

## 0.1.0

- **Breaking:** `generate-schema` emits the new table-marker shape:
  `final class X extends TableRef<X>` with a private const constructor,
  a `static const table` singleton, columns holding a typed `table` reference
  instead of a repeated name string, and a `columns` getter override as the
  default projection.
- Column declarations are emitted one argument per line with trailing commas,
  so generated files stay diff-stable under `dart format`.
- New guard: a column whose camelCase field name collides with an inherited
  `TableRef`/`Object` member (`table`, `table_name`, `alias`, `columns`, `col`,
  `aliased`, ...) fails generation with a clear error instead of emitting code
  that won't compile.
- Requires `basalt >=0.1.0 <0.2.0`.

## 0.0.2

- Widened the core constraint to `basalt >=0.0.1 <0.1.0` so the CLI resolves alongside any
  0.0.x core release (caret on 0.0.x pins a single version). No functional changes.

## 0.0.1

Initial development release of the `basalt` command-line tool.

- Migrations: `migration generate <name>` / `run` / `revert` / `redo` / `list`, tracked in
  `__basalt_schema_migrations`.
- `database reset` and `generate-schema` (typed schema from a live database via introspection).
- `setup` and `--config <path>` for `basalt.yaml`.
- Backend-agnostic: no dependency on any backend package. `bin/basalt.dart` bootstraps a
  generated entrypoint (`.dart_tool/basalt/`) that imports the `backend:` package from
  `basalt.yaml` through the `BasaltAdapter` seam.
