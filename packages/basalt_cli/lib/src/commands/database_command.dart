import 'package:args/command_runner.dart';
import 'package:basalt/tooling.dart';

import 'reset_command.dart';

final class DatabaseCommand extends Command<int> {
  DatabaseCommand(BasaltAdapter adapter) {
    addSubcommand(ResetCommand(adapter));
  }
  @override
  final name = 'database';
  @override
  final description = 'Database-level operations.';
}
