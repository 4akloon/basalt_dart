import 'dart:io';

import 'db_command.dart';

final class RunCommand extends DbCommand {
  @override
  final name = 'run';
  @override
  final description = 'Apply all pending migrations.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        final ran = await runner.runPending();
        if (ran.isEmpty) {
          stdout.writeln('No pending migrations.');
        } else {
          for (final version in ran) {
            stdout.writeln('Applied $version');
          }
        }
        return 0;
      });
}
