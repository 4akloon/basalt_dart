# diesel_devtools_extension

![Flutter](https://img.shields.io/badge/Flutter-web-02569B?logo=flutter&logoColor=white)
![DevTools](https://img.shields.io/badge/DevTools-extension-5C2D91)
![Part of](https://img.shields.io/badge/part_of-diesel__dart-informational)

**The Flutter web UI behind the DevTools "diesel" tab.** It talks to the connected app's `ext.diesel.*` VM
service extensions (registered by the [`package:diesel/devtools.dart`](../diesel#devtools-inspector) runtime)
to list instances, browse / filter / sort tables, view and edit rows, and run raw SQL.

It lives under `packages/` for consistency but is intentionally **not a member of the Dart pub workspace**
(absent from the root `workspace:` list, no `resolution: workspace`), so it resolves against the Flutter SDK
via `flutter pub get` independently — the runtime packages stay pure Dart and `dart pub get` never touches
Flutter deps.

## Contents

- [Opening the inspector](#opening-the-inspector)
- [Develop the UI](#develop-the-ui)
- [Build into the diesel package](#build-into-the-diesel-package)

## Opening the inspector

The runtime + how to open the tab are documented in the core package:
[`diesel` → DevTools inspector](../diesel#devtools-inspector). In short: `DieselDevTools.register(conn)` in
your app, then `dart run example/tool/inspect.dart` and enable **diesel** in DevTools' Extensions menu.

## Develop the UI

Run against the simulated DevTools environment (no app connection needed for layout work):

```bash
flutter pub get
flutter run -d chrome --dart-define=use_simulated_environment=true
```

For a live run, launch a target that registers a connection (e.g.
`dart run --observe example/tool/inspector_demo.dart`), then open DevTools on its VM service URI and use the
diesel tab.

## Build into the diesel package

The compiled output is git-ignored; regenerate it into the `diesel` package (which ships the extension) with:

```bash
dart run devtools_extensions build_and_copy \
  --source=. --dest=../diesel/extension/devtools
dart run devtools_extensions validate --package=../diesel
```
