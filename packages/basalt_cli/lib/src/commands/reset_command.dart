import 'dart:io';

import 'db_command.dart';

final class ResetCommand extends DbCommand {
  ResetCommand(super.adapter);

  @override
  final name = 'reset';
  @override
  final description = 'Drop the database and re-run all migrations.';

  @override
  Future<int> run() async {
    final config = loadConfig();
    await adapter.reset(config.database);
    return withRunner((config, runner) async {
      final ran = await runner.runPending();
      stdout.writeln('Database reset. Applied ${ran.length} migration(s).');
      return 0;
    });
  }
}
