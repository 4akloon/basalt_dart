# diesel_devtools

A [DevTools extension](https://docs.flutter.dev/tools/devtools/extensions) inspector for the
[Diesel Dart](../../README.md) ORM — Isar-inspector style. From the **diesel** tab in DevTools you can:

- pick the active database instance (when several are open),
- browse the table list and each table's columns / primary keys / foreign keys,
- page through a table's rows, sort by column, and filter (per-column predicates),
- edit a row in place (by primary key),
- run raw SQL (reads **and** writes).

It is **dev-only**: connections are exposed only after an explicit `register` call, and the underlying
`ext.diesel.*` VM service extensions exist only while the VM service is running (debug / `--observe`).
Nothing ships in a release build that never calls `register`.

## Usage

Add the dependency (dev-only is fine):

```yaml
dev_dependencies:
  diesel_devtools: ^0.0.1
```

Register each connection you want to inspect:

```dart
import 'package:diesel_devtools/diesel_devtools.dart';

final conn = SqliteConnection.open('app.db'); // or PostgresConnection…
DieselDevTools.register(conn, name: 'main');
```

Then build the extension's web app once (it's git-ignored) and open DevTools.

```bash
cd packages/diesel_devtools_extension
dart run devtools_extensions build_and_copy \
  --source=. --dest=../diesel_devtools/extension/devtools
```

**Opening the diesel tab.** DevTools discovers extensions from the project root, which it learns from
the **Dart Tooling Daemon (DTD)**. A plain `dart run --observe` starts no DTD (and even `--print-dtd`
starts one with no workspace root set), so the Extensions menu stays empty. Pick one:

- **One command (no IDE):** a launcher that starts a DTD, points it at this repo, runs the demo, and
  opens DevTools wired to both:

  ```bash
  dart run packages/diesel_devtools/tool/inspect.dart          # or: … inspect.dart path/to/your_app.dart
  ```

  (Add `--check` to just confirm the DTD sees this repo's packages, without launching anything.)

- **From an IDE:** open the project in VS Code / IntelliJ, run your app (or `tool/inspector_demo.dart`)
  in debug, then "Open DevTools" from the run session — the IDE wires up the app + DTD automatically.

Then open the **Extensions** menu (upper-right in DevTools) and enable **diesel** — extensions are
disabled until you turn them on; the **diesel** tab then appears. (Flutter debug mode / `flutter run`
starts a DTD for you, so there the tab shows up without the launcher.)

Backend-agnostic: because it targets the `Connection` interface, the same inspector works for SQLite and
Postgres with no extra code.

## Architecture

- **Runtime (this package, pure Dart):** a registry of live `Connection`s plus an `InspectorService`
  core, surfaced over the VM service as `ext.diesel.listInstances` / `getSchema` / `getTableData` /
  `runSql`. `InspectorService` is a plain, unit-tested class — the service-extension handlers are thin
  adapters that parse string params and JSON-encode results.
- **UI (`packages/diesel_devtools_extension/`, Flutter):** a Flutter web app compiled into
  `extension/devtools/build/` that DevTools loads and which calls those service extensions. It's under
  `packages/` but not a Dart-workspace member (it's a Flutter app).

## Try it without DevTools

```bash
dart run --observe packages/diesel_devtools/tool/inspector_demo.dart
```

Seeds an in-memory database, prints what the inspector core sees, and stays alive so you can attach
DevTools to the printed VM service URI.
