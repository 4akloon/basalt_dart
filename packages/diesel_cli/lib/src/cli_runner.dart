import 'package:args/command_runner.dart';

import 'commands/database_command.dart';
import 'commands/migration_command.dart';
import 'commands/print_schema_command.dart';
import 'commands/setup_command.dart';

/// Builds the `diesel_dart` command tree.
final class CliRunner {
  const CliRunner();

  CommandRunner<int> build() {
    return CommandRunner<int>(
      'diesel_dart',
      'Migrations and codegen for the Diesel Dart ORM.',
    )
      ..addCommand(SetupCommand())
      ..addCommand(MigrationCommand())
      ..addCommand(DatabaseCommand())
      ..addCommand(PrintSchemaCommand());
  }
}
