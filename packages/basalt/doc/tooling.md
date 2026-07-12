# CLI Adapters & Tooling

`package:basalt/tooling.dart` is the seam between the basalt CLI and database
backends. The CLI has **no dependency on concrete backend packages** — a
project picks its backend in `basalt.yaml`:

```yaml
backend: basalt_sqlite   # required — no default; picking a backend is explicit
database:
  path: app.db
```

The `basalt` executable generates a bootstrap entrypoint under
`.dart_tool/basalt/` that imports the chosen package's adapter and runs the
actual CLI with it (the same model `build_runner` uses).

## Writing a backend adapter

A backend package plugs in with two things:

1. An implementation of `BasaltAdapter`:

```dart
final class MyDbAdapter extends BasaltAdapter {
  const MyDbAdapter();

  @override
  String get name => 'mydb';

  @override
  Future<Connection> open(Map<String, Object?> options) async {
    // interpret your own option keys from the `database:` section
  }

  @override
  Future<void> reset(Map<String, Object?> options) async {
    // drop/delete the database so migrations can rebuild it
  }
}
```

2. A `lib/adapter.dart` exposing it under the conventional name the generated
   entrypoint imports:

```dart
const BasaltAdapter adapter = MyDbAdapter();
```

Users then set `backend: my_db_package` in `basalt.yaml` and add the package
to their `dev_dependencies`. No CLI changes needed.

## Connection options

`open`/`reset` receive the raw `database:` map from `basalt.yaml`. The adapter
defines its own keys (whether it supports a `url`, a `path`, `host`/`port`,
...) and validates them — throw `ArgumentError` naming the adapter for unknown
or missing keys. If the `DATABASE_URL` environment variable is set, the CLI
stores it under the map's `url` key before handing the map over.

## Type presets for `generate-schema`

`SchemaTypeOverrides` maps introspected columns to the Dart type and `SqlType`
expression emitted in the generated schema, resolved with the precedence
**specific column > native type > canonical type** (`TypeOverride` entries are
emitted verbatim). An adapter ships two preset tiers:

- `typeOverrides` — always applied; must emit **portable core types** only.
  Example: the SQLite adapter maps columns declared `BOOLEAN`/`DATETIME`
  (which SQLite affinity collapses to `INTEGER`) back to `bool`/`DateTime`.
- `nativeTypeOverrides` — applied only when the project sets
  `native_types: true`; may emit the backend package's own `SqlType`s
  (e.g. a Postgres `jsonb` codec), making the generated schema
  backend-specific.

User `types:` overrides in `basalt.yaml` always win over presets; the layering
is implemented by `SchemaTypeOverrides.overlay` (the receiver wins per key).
Register only the non-nullable form of an override — a nullable column derives
its variant automatically via `TypeOverride.asNullable` (wrapping the codec in
`NullableSqlType`).
