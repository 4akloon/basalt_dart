# basalt_devtools_extension

![Flutter](https://img.shields.io/badge/Flutter-web-02569B?logo=flutter&logoColor=white)
![DevTools](https://img.shields.io/badge/DevTools-extension-5C2D91)
![Part of](https://img.shields.io/badge/part_of-basalt__dart-informational)

**The Flutter web UI behind the DevTools "basalt" tab.** It talks to the connected app's `ext.basalt.*` VM
service extensions (registered by the [`package:basalt/devtools.dart`](../basalt#devtools-inspector) runtime)
to list instances, browse / filter / sort tables, view and edit rows, and run raw SQL.

It lives under `packages/` for consistency but is intentionally **not a member of the Dart pub workspace**
(absent from the root `workspace:` list, no `resolution: workspace`), so it resolves against the Flutter SDK
via `flutter pub get` independently — the runtime packages stay pure Dart and `dart pub get` never touches
Flutter deps.

## Contents

- [Opening the inspector](#opening-the-inspector)
- [Develop the UI](#develop-the-ui)
- [Build into the basalt package](#build-into-the-basalt-package)

## Opening the inspector

The runtime + how to open the tab are documented in the core package:
[`basalt` → DevTools inspector](../basalt#devtools-inspector). In short: `BasaltDevTools.register(conn)` in
your app, then `dart run example/tool/inspect.dart` and enable **basalt** in DevTools' Extensions menu.

## Develop the UI

Run against the simulated DevTools environment (no app connection needed for layout work):

```bash
flutter pub get
flutter run -d chrome --dart-define=use_simulated_environment=true
```

For a live run, launch a target that registers a connection (e.g.
`dart run --observe example/tool/inspector_demo.dart`), then open DevTools on its VM service URI and use the
basalt tab.

## Build into the basalt package

The compiled output is git-ignored; regenerate it into the `basalt` package (which ships the extension) with:

```bash
dart run devtools_extensions build_and_copy \
  --source=. --dest=../basalt/extension/devtools
dart run devtools_extensions validate --package=../basalt
```
