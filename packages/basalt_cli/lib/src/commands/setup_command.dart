import 'dart:io';

import 'db_command.dart';

final class SetupCommand extends DbCommand {
  SetupCommand(super.adapter);

  @override
  final name = 'setup';
  @override
  final description =
      'Create the migrations directory and database, then run pending migrations.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        Directory(config.migrationsDir).createSync(recursive: true);
        final ran = await runner.runPending();
        stdout.writeln('Setup complete. Applied ${ran.length} migration(s).');
        return 0;
      });
}
