import 'package:args/command_runner.dart';
import 'package:basalt/tooling.dart';

import 'generate_command.dart';
import 'list_command.dart';
import 'redo_command.dart';
import 'revert_command.dart';
import 'run_command.dart';

final class MigrationCommand extends Command<int> {
  MigrationCommand(BasaltAdapter adapter) {
    addSubcommand(GenerateCommand());
    addSubcommand(RunCommand(adapter));
    addSubcommand(RevertCommand(adapter));
    addSubcommand(RedoCommand(adapter));
    addSubcommand(ListCommand(adapter));
  }
  @override
  final name = 'migration';
  @override
  final description = 'Generate, run, and revert migrations.';
}
