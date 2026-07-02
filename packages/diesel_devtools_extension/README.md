# diesel_devtools_extension

The Flutter web app for the **diesel** DevTools tab. It talks to the connected app's
`ext.diesel.*` VM service extensions (registered by the `package:diesel/devtools.dart` runtime) to list
instances, browse/filter tables, view/edit rows, and run SQL.

It lives under `packages/` for consistency but is intentionally **not** a member of the Dart pub
workspace (it's absent from the root `workspace:` list and has no `resolution: workspace`), so it
resolves against the Flutter SDK via `flutter pub get` independently — the runtime packages stay pure
Dart and `dart pub get` never has to touch Flutter deps.

## Develop the UI

Run against the simulated DevTools environment (no app connection needed for layout work):

```bash
flutter run -d chrome --dart-define=use_simulated_environment=true
```

For a live run, launch a target that registers a connection (e.g.
`dart run --observe example/tool/inspector_demo.dart`), then open DevTools on its VM service URI and use
the diesel tab.

## Build & publish into the package

The compiled output is git-ignored; regenerate it into the `diesel` package (which ships the extension)
with:

```bash
dart run devtools_extensions build_and_copy \
  --source=. --dest=../diesel/extension/devtools
dart run devtools_extensions validate --package=../diesel
```
