import 'package:args/command_runner.dart';

import 'commands/database_command.dart';
import 'commands/generate_schema_command.dart';
import 'commands/migration_command.dart';
import 'commands/setup_command.dart';

/// Builds the `basalt` command tree.
final class CliRunner {
  const CliRunner();

  CommandRunner<int> build() {
    final runner = CommandRunner<int>(
      'basalt',
      'Migrations and codegen for the Basalt Dart ORM.',
    )
      ..addCommand(SetupCommand())
      ..addCommand(MigrationCommand())
      ..addCommand(DatabaseCommand())
      ..addCommand(GenerateSchemaCommand());
    runner.argParser.addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'basalt.yaml',
      help: 'Path to the basalt.yaml config file.',
    );
    return runner;
  }
}
