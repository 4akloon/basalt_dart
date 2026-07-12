import 'dart:io';

import 'db_command.dart';

final class ListCommand extends DbCommand {
  ListCommand(super.adapter);

  @override
  final name = 'list';
  @override
  final description = 'Show applied and pending migrations.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        final status = await runner.status();
        stdout.writeln('Applied (${status.applied.length}):');
        for (final version in status.applied) {
          stdout.writeln('  [X] $version');
        }
        stdout.writeln('Pending (${status.pending.length}):');
        for (final migration in status.pending) {
          stdout.writeln('  [ ] ${migration.version}_${migration.name}');
        }
        return 0;
      });
}
