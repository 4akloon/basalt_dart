/// CLI adapter entrypoint for the Postgres backend.
///
/// Kept separate from `package:basalt_postgres/basalt_postgres.dart` so the
/// runtime surface doesn't pull in tooling types. The basalt CLI's generated
/// bootstrap imports this library and reads the conventional top-level
/// [adapter] constant (see `package:basalt/tooling.dart`).
library;

import 'package:basalt/tooling.dart';

import 'src/postgres_adapter.dart';

export 'src/postgres_adapter.dart';
export 'src/postgres_endpoint.dart';

/// The adapter instance the basalt CLI bootstraps with.
const BasaltAdapter adapter = PostgresAdapter();
