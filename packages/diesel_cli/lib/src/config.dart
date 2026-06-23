import 'dart:io';

import 'package:yaml/yaml.dart';

/// CLI configuration, resolved from `DATABASE_URL` (env) with `diesel.yaml` as
/// a fallback / for the migrations directory.
final class DieselConfig {
  final String databaseUrl;
  final String migrationsDir;

  const DieselConfig({required this.databaseUrl, required this.migrationsDir});

  /// SQLite filesystem path (scheme stripped). `:memory:` is passed through.
  String get databasePath {
    for (final scheme in const ['sqlite://', 'sqlite:', 'file://', 'file:']) {
      if (databaseUrl.startsWith(scheme)) {
        return databaseUrl.substring(scheme.length);
      }
    }
    return databaseUrl;
  }

  static DieselConfig load({
    Map<String, String>? environment,
    String configPath = 'diesel.yaml',
  }) {
    final env = environment ?? Platform.environment;
    var databaseUrl = env['DATABASE_URL'];
    var migrationsDir = 'migrations';

    final file = File(configPath);
    if (file.existsSync()) {
      final yaml = loadYaml(file.readAsStringSync());
      if (yaml is Map) {
        databaseUrl ??= yaml['database_url'] as String?;
        if (yaml['migrations_dir'] case final String dir) migrationsDir = dir;
      }
    }

    if (databaseUrl case final url?) {
      return DieselConfig(databaseUrl: url, migrationsDir: migrationsDir);
    }
    throw StateError(
        'No database configured. Set DATABASE_URL or `database_url:` in diesel.yaml.');
  }
}
