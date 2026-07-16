# Changelog

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
