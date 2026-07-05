import 'package:args/command_runner.dart';

import 'commands/database_command.dart';
import 'commands/migration_command.dart';
import 'commands/print_schema_command.dart';
import 'commands/setup_command.dart';

/// Builds the `basalt` command tree.
final class CliRunner {
  const CliRunner();

  CommandRunner<int> build() {
    return CommandRunner<int>(
      'basalt',
      'Migrations and codegen for the Basalt Dart ORM.',
    )
      ..addCommand(SetupCommand())
      ..addCommand(MigrationCommand())
      ..addCommand(DatabaseCommand())
      ..addCommand(PrintSchemaCommand());
  }
}
