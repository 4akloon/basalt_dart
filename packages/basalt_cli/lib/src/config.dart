import 'dart:io';

import 'package:basalt/tooling.dart';
import 'package:yaml/yaml.dart';

/// CLI configuration, loaded from `basalt.yaml`.
///
/// The `database:` section is kept as a raw map and handed to the backend
/// adapter as-is — its keys are adapter-specific (`path:` for SQLite; `url:`
/// or `host:`/`port:`/... for Postgres). If the `DATABASE_URL` environment
/// variable is set it overrides the map's `url` key.
///
/// {@category getting-started}
final class BasaltConfig {
  const BasaltConfig({
    required this.database,
    required this.backend,
    required this.migrationsDir,
    required this.schemaOutput,
    this.nativeTypes = false,
    this.typeOverrides = const SchemaTypeOverrides.empty(),
  });

  /// Raw `database:` section — connection options interpreted by the adapter.
  final Map<String, Object?> database;

  /// Backend package name from the required `backend:` key (e.g.
  /// `basalt_sqlite`). Choosing a backend is an explicit decision — there is
  /// no default.
  final String backend;

  final String migrationsDir;
  final String schemaOutput;

  /// Whether `generate-schema` applies the adapter's backend-native type
  /// presets (`native_types:` in `basalt.yaml`, default false).
  final bool nativeTypes;

  /// Column-type overrides for `generate-schema`, from the optional `types:`
  /// block of `basalt.yaml`. Layered over the adapter's presets.
  final SchemaTypeOverrides typeOverrides;

  static BasaltConfig load({
    Map<String, String>? environment,
    String configPath = 'basalt.yaml',
  }) {
    final env = environment ?? Platform.environment;
    String? backend;
    var database = <String, Object?>{};
    var migrationsDir = 'migrations';
    var schemaOutput = 'lib/schema.dart';
    var nativeTypes = false;
    var typeOverrides = const SchemaTypeOverrides.empty();

    final file = File(configPath);
    if (file.existsSync()) {
      final yaml = loadYaml(file.readAsStringSync());
      if (yaml is Map) {
        if (yaml['database_url'] != null) {
          throw StateError(
            'basalt.yaml: `database_url:` is no longer supported. Move it '
            'into the `database:` section using the keys your backend '
            'adapter defines (e.g. `database:\n  path: app.db` for SQLite).',
          );
        }
        backend = _backend(yaml['backend']);
        database = _database(yaml['database']);
        if (yaml['migrations_dir'] case final String dir) migrationsDir = dir;
        if (yaml['schema_output'] case final String path) schemaOutput = path;
        nativeTypes = _nativeTypes(yaml['native_types']);
        typeOverrides =
            const SchemaTypeOverridesParser().parse(yaml['types']);
      }
    }

    if (env['DATABASE_URL'] case final url?) {
      database = {...database, 'url': url};
    }

    if (backend == null) {
      throw StateError(
        'No backend configured. Add `backend:` to basalt.yaml '
        '(e.g. `backend: basalt_sqlite`).',
      );
    }
    if (database.isEmpty) {
      throw StateError(
        'No database configured. Add a `database:` section to basalt.yaml '
        'or set DATABASE_URL.',
      );
    }
    return BasaltConfig(
      database: database,
      backend: backend,
      migrationsDir: migrationsDir,
      schemaOutput: schemaOutput,
      nativeTypes: nativeTypes,
      typeOverrides: typeOverrides,
    );
  }

  static String? _backend(Object? node) {
    if (node == null) return null;
    if (node is! String || !RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(node)) {
      throw StateError(
        'basalt.yaml: `backend:` must be a Dart package name '
        "(got '$node').",
      );
    }
    return node;
  }

  static Map<String, Object?> _database(Object? node) {
    if (node == null) return {};
    if (node is! Map) {
      throw StateError('basalt.yaml: `database:` must be a mapping.');
    }
    return {for (final entry in node.entries) entry.key.toString(): entry.value};
  }

  static bool _nativeTypes(Object? node) {
    if (node == null) return false;
    if (node is! bool) {
      throw StateError('basalt.yaml: `native_types:` must be a bool.');
    }
    return node;
  }
}
