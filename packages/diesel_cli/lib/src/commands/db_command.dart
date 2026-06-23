import 'package:args/command_runner.dart';

import '../config.dart';
import '../connection_factory.dart';
import '../migration_runner.dart';

/// Shared plumbing: resolve config, open a connection, build a runner.
abstract base class DbCommand extends Command<int> {
  Future<int> withRunner(
      Future<int> Function(DieselConfig config, MigrationRunner runner)
          action) async {
    final config = DieselConfig.load();
    final connection = const ConnectionFactory().open(config);
    try {
      return await action(config, MigrationRunner(connection, config.migrationsDir));
    } finally {
      await connection.close();
    }
  }
}
