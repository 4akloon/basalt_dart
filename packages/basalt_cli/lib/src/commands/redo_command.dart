import 'dart:io';

import 'db_command.dart';

final class RedoCommand extends DbCommand {
  @override
  final name = 'redo';
  @override
  final description = 'Revert and re-apply the most recent migration.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        final reverted = await runner.revertLast();
        if (reverted == null) {
          stdout.writeln('Nothing to redo.');
          return 0;
        }
        await runner.runPending();
        stdout.writeln('Redid $reverted');
        return 0;
      });
}
