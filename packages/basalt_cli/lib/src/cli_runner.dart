import 'package:args/command_runner.dart';
import 'package:basalt/tooling.dart';

import 'commands/database_command.dart';
import 'commands/generate_schema_command.dart';
import 'commands/migration_command.dart';
import 'commands/setup_command.dart';

/// Builds the `basalt` command tree around the backend [adapter] the
/// bootstrap entrypoint was generated with.
///
/// {@category getting-started}
final class CliRunner {
  const CliRunner(this.adapter);

  /// The backend adapter every database-touching command runs against.
  final BasaltAdapter adapter;

  CommandRunner<int> build() {
    final runner = CommandRunner<int>(
      'basalt',
      'Migrations and codegen for the Basalt Dart ORM.',
    )
      ..addCommand(SetupCommand(adapter))
      ..addCommand(MigrationCommand(adapter))
      ..addCommand(DatabaseCommand(adapter))
      ..addCommand(GenerateSchemaCommand(adapter));
    runner.argParser.addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'basalt.yaml',
      help: 'Path to the basalt.yaml config file.',
    );
    return runner;
  }
}
