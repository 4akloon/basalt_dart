import 'package:args/command_runner.dart';

import 'reset_command.dart';

final class DatabaseCommand extends Command<int> {
  DatabaseCommand() {
    addSubcommand(ResetCommand());
  }
  @override
  final name = 'database';
  @override
  final description = 'Database-level operations.';
}
