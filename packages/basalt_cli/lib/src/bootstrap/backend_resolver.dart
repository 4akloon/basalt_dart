import 'dart:io';

import 'package:yaml/yaml.dart';

/// Resolves which backend package the CLI should bootstrap with, from the
/// **required** `backend:` key of `basalt.yaml`.
///
/// There is no default — choosing a backend is an explicit decision. A missing
/// config file or `backend:` key throws [StateError]; when a Postgres-looking
/// `database.url`/`DATABASE_URL` is present, the message suggests
/// `backend: basalt_postgres` specifically.
final class BackendResolver {
  const BackendResolver();

  /// The backend package name for the project configured at [configPath].
  String resolve(String configPath, {Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    Object? backendNode;
    Object? urlNode;

    final file = File(configPath);
    if (file.existsSync()) {
      final yaml = loadYaml(file.readAsStringSync());
      if (yaml is Map) {
        backendNode = yaml['backend'];
        if (yaml['database'] case final Map database) {
          urlNode = database['url'];
        }
      }
    }

    if (backendNode != null) {
      if (backendNode is! String ||
          !RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(backendNode)) {
        throw StateError(
          'basalt.yaml: `backend:` must be a Dart package name '
          "(got '$backendNode').",
        );
      }
      return backendNode;
    }

    final url = env['DATABASE_URL'] ?? (urlNode is String ? urlNode : null);
    final suggestion = url != null &&
            (url.startsWith('postgres://') || url.startsWith('postgresql://'))
        ? 'basalt_postgres'
        : 'basalt_sqlite';
    throw StateError(
      'No backend configured. Set `backend:` in $configPath '
      '(e.g. `backend: $suggestion`).',
    );
  }
}
