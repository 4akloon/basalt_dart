import 'package:args/command_runner.dart';
import 'package:basalt/migration.dart';
import 'package:basalt/tooling.dart';

import '../config.dart';
import '../directory_migration_source.dart';

/// Shared plumbing: resolve config, open a connection via the backend
/// [adapter], build a migration runner.
abstract base class DbCommand extends Command<int> {
  DbCommand(this.adapter);

  /// The backend adapter the CLI was bootstrapped with.
  final BasaltAdapter adapter;

  /// Loads `basalt.yaml`, honoring the global `--config` option.
  BasaltConfig loadConfig() => BasaltConfig.load(
        configPath: globalResults?['config'] as String? ?? 'basalt.yaml',
      );

  Future<int> withRunner(
    Future<int> Function(BasaltConfig config, MigrationRunner runner) action,
  ) async {
    final config = loadConfig();
    final connection = await adapter.open(config.database);
    try {
      return await action(
        config,
        MigrationRunner(
          connection,
          DirectoryMigrationSource(config.migrationsDir),
        ),
      );
    } finally {
      await connection.close();
    }
  }
}
