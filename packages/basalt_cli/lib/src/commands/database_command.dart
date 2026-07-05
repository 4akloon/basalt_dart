import 'package:args/command_runner.dart';

import 'reset_command.dart';

final class DatabaseCommand extends Command<int> {
  @override
  final name = 'database';
  @override
  final description = 'Database-level operations.';

  DatabaseCommand() {
    addSubcommand(ResetCommand());
  }
}
