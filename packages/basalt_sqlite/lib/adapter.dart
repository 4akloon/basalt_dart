/// CLI adapter entrypoint for the SQLite backend.
///
/// Kept separate from `package:basalt_sqlite/basalt_sqlite.dart` so the
/// runtime surface doesn't pull in tooling types. The basalt CLI's generated
/// bootstrap imports this library and reads the conventional top-level
/// [adapter] constant (see `package:basalt/tooling.dart`).
library;

import 'package:basalt/tooling.dart';

import 'src/sqlite_adapter.dart';

export 'src/sqlite_adapter.dart';

/// The adapter instance the basalt CLI bootstraps with.
const BasaltAdapter adapter = SqliteAdapter();
