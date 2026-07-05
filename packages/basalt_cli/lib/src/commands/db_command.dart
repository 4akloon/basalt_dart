import 'package:args/command_runner.dart';

import '../config.dart';
import '../connection_factory.dart';
import '../migration_runner.dart';

/// Shared plumbing: resolve config, open a connection, build a runner.
abstract base class DbCommand extends Command<int> {
  Future<int> withRunner(
      Future<int> Function(BasaltConfig config, MigrationRunner runner)
          action) async {
    final config = BasaltConfig.load(
      configPath: globalResults?['config'] as String? ?? 'basalt.yaml',
    );
    final connection = await const ConnectionFactory().open(config);
    try {
      return await action(config, MigrationRunner(connection, config.migrationsDir));
    } finally {
      await connection.close();
    }
  }
}
