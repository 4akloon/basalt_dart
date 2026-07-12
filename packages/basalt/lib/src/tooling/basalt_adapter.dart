import 'dart:async';

import '../connection.dart';
import 'schema_type_overrides.dart';

/// A database backend plugged into the basalt CLI.
///
/// The CLI never imports concrete backends: `basalt.yaml`'s `backend:` key
/// names a package, and the generated bootstrap entrypoint imports that
/// package's `lib/adapter.dart`, which by convention exposes a top-level
/// `const BasaltAdapter adapter;`.
///
/// The adapter owns everything backend-specific the CLI needs: opening a
/// [Connection] from the raw `database:` options, destroying the database for
/// `database reset`, and the type presets consulted by `generate-schema`.
///
/// {@category tooling}
abstract base class BasaltAdapter {
  const BasaltAdapter();

  /// Short backend name for diagnostics, e.g. `'sqlite'`.
  String get name;

  /// Opens a live connection described by [options] — the raw `database:`
  /// section of `basalt.yaml`, passed through as-is.
  ///
  /// The adapter defines its own option keys and validates them: an unknown
  /// key or a missing required one throws [ArgumentError] with a message that
  /// names the adapter.
  Future<Connection> open(Map<String, Object?> options);

  /// Destroys the database described by [options] so `database reset` can
  /// rebuild it from scratch by re-running migrations.
  Future<void> reset(Map<String, Object?> options);

  /// Always-applied `generate-schema` presets.
  ///
  /// Must map to portable core `SqlType`s only, so the generated schema keeps
  /// working on every backend. Lower precedence than the user's `types:`
  /// overrides (see `SchemaTypeOverrides.layered`).
  SchemaTypeOverrides get typeOverrides => const SchemaTypeOverrides.empty();

  /// Backend-native `generate-schema` presets, applied only when the project
  /// opts in with `native_types: true` in `basalt.yaml`.
  ///
  /// May map to `SqlType`s shipped by the backend package; the generated
  /// schema then imports that package and is no longer backend-portable.
  SchemaTypeOverrides get nativeTypeOverrides =>
      const SchemaTypeOverrides.empty();
}
