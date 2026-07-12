import 'dart:io';

import 'db_command.dart';

final class RevertCommand extends DbCommand {
  RevertCommand(super.adapter);

  @override
  final name = 'revert';
  @override
  final description = 'Revert the most recent migration.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        final reverted = await runner.revertLast();
        stdout.writeln(
          reverted == null ? 'Nothing to revert.' : 'Reverted $reverted',
        );
        return 0;
      });
}
