import 'package:args/command_runner.dart';

import 'generate_command.dart';
import 'list_command.dart';
import 'redo_command.dart';
import 'revert_command.dart';
import 'run_command.dart';

final class MigrationCommand extends Command<int> {
  @override
  final name = 'migration';
  @override
  final description = 'Generate, run, and revert migrations.';

  MigrationCommand() {
    addSubcommand(GenerateCommand());
    addSubcommand(RunCommand());
    addSubcommand(RevertCommand());
    addSubcommand(RedoCommand());
    addSubcommand(ListCommand());
  }
}
