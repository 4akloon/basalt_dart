import 'dart:io';

import 'package:args/command_runner.dart';

import '../config.dart';
import '../connection_factory.dart';
import '../migration_runner.dart';

final class ResetCommand extends Command<int> {
  @override
  final name = 'reset';
  @override
  final description = 'Drop the database and re-run all migrations.';

  @override
  Future<int> run() async {
    final config = BasaltConfig.load(
      configPath: globalResults?['config'] as String? ?? 'basalt.yaml',
    );
    // SQLite reset = drop the file and re-create. (Per-backend reset can live in
    // the backend later.)
    final path = config.databasePath;
    if (path != ':memory:') {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }
    final connection = await const ConnectionFactory().open(config);
    try {
      final ran = await MigrationRunner(connection, config.migrationsDir).runPending();
      stdout.writeln('Database reset. Applied ${ran.length} migration(s).');
      return 0;
    } finally {
      await connection.close();
    }
  }
}
