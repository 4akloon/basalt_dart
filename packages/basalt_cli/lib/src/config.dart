import 'dart:io';

import 'package:yaml/yaml.dart';

/// CLI configuration, resolved from `DATABASE_URL` (env) with `basalt.yaml` as
/// a fallback / for the migrations directory.
final class BasaltConfig {
  final String databaseUrl;
  final String migrationsDir;
  final String schemaOutput;

  const BasaltConfig({
    required this.databaseUrl,
    required this.migrationsDir,
    required this.schemaOutput,
  });

  /// SQLite filesystem path (scheme stripped). `:memory:` is passed through.
  String get databasePath {
    for (final scheme in const ['sqlite://', 'sqlite:', 'file://', 'file:']) {
      if (databaseUrl.startsWith(scheme)) {
        return databaseUrl.substring(scheme.length);
      }
    }
    return databaseUrl;
  }

  static BasaltConfig load({
    Map<String, String>? environment,
    String configPath = 'basalt.yaml',
  }) {
    final env = environment ?? Platform.environment;
    var databaseUrl = env['DATABASE_URL'];
    var migrationsDir = 'migrations';
    var schemaOutput = 'lib/schema.dart';

    final file = File(configPath);
    if (file.existsSync()) {
      final yaml = loadYaml(file.readAsStringSync());
      if (yaml is Map) {
        databaseUrl ??= yaml['database_url'] as String?;
        if (yaml['migrations_dir'] case final String dir) migrationsDir = dir;
        if (yaml['schema_output'] case final String path) schemaOutput = path;
      }
    }

    if (databaseUrl case final url?) {
      return BasaltConfig(
        databaseUrl: url,
        migrationsDir: migrationsDir,
        schemaOutput: schemaOutput,
      );
    }
    throw StateError(
        'No database configured. Set DATABASE_URL or `database_url:` in basalt.yaml.');
  }
}
