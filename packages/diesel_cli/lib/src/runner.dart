import 'dart:io';

import 'package:args/command_runner.dart';

import 'config.dart';
import 'database.dart';
import 'migrations.dart';
import 'schema_gen.dart';

/// Builds the `diesel_dart` command tree.
CommandRunner<int> buildRunner() {
  return CommandRunner<int>(
    'diesel_dart',
    'Migrations and codegen for the Diesel Dart ORM.',
  )
    ..addCommand(SetupCommand())
    ..addCommand(MigrationCommand())
    ..addCommand(DatabaseCommand())
    ..addCommand(PrintSchemaCommand());
}

/// Shared plumbing: resolve config, open a connection, build a runner.
abstract base class _DbCommand extends Command<int> {
  Future<int> withRunner(
      Future<int> Function(DieselConfig config, MigrationRunner runner) action) async {
    final config = DieselConfig.load();
    final connection = openConnection(config);
    try {
      return await action(config, MigrationRunner(connection, config.migrationsDir));
    } finally {
      await connection.close();
    }
  }
}

final class SetupCommand extends _DbCommand {
  @override
  final name = 'setup';
  @override
  final description =
      'Create the migrations directory and database, then run pending migrations.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        Directory(config.migrationsDir).createSync(recursive: true);
        final ran = await runner.runPending();
        stdout.writeln('Setup complete. Applied ${ran.length} migration(s).');
        return 0;
      });
}

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

final class GenerateCommand extends Command<int> {
  @override
  final name = 'generate';
  @override
  final description = 'Scaffold a new migration: migration generate <name>.';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const [];
    if (rest.isEmpty) {
      usageException('Provide a migration name: migration generate <name>.');
    }
    final config = DieselConfig.load();
    final dir = generateMigration(rest.first, config.migrationsDir);
    stdout.writeln('Created $dir');
    return 0;
  }
}

final class RunCommand extends _DbCommand {
  @override
  final name = 'run';
  @override
  final description = 'Apply all pending migrations.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        final ran = await runner.runPending();
        if (ran.isEmpty) {
          stdout.writeln('No pending migrations.');
        } else {
          for (final version in ran) {
            stdout.writeln('Applied $version');
          }
        }
        return 0;
      });
}

final class RevertCommand extends _DbCommand {
  @override
  final name = 'revert';
  @override
  final description = 'Revert the most recent migration.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        final reverted = await runner.revertLast();
        stdout.writeln(
            reverted == null ? 'Nothing to revert.' : 'Reverted $reverted');
        return 0;
      });
}

final class RedoCommand extends _DbCommand {
  @override
  final name = 'redo';
  @override
  final description = 'Revert and re-apply the most recent migration.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        final reverted = await runner.revertLast();
        if (reverted == null) {
          stdout.writeln('Nothing to redo.');
          return 0;
        }
        await runner.runPending();
        stdout.writeln('Redid $reverted');
        return 0;
      });
}

final class ListCommand extends _DbCommand {
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

final class PrintSchemaCommand extends _DbCommand {
  @override
  final name = 'print-schema';
  @override
  final description =
      'Generate the typed schema (tables and columns only) from the database.';

  PrintSchemaCommand() {
    argParser.addOption('output',
        abbr: 'o', help: 'Write to this file instead of stdout.');
  }

  @override
  Future<int> run() => withRunner((config, runner) async {
        final tables = await runner.connection.introspect();
        if (tables.isEmpty) {
          stderr.writeln('Warning: no tables found in the database. '
              'Run `diesel_dart migration run` first.');
        }
        final source = generateSchema(tables);
        if (argResults?['output'] case final String path) {
          File(path).writeAsStringSync(source);
          stdout.writeln('Wrote ${tables.length} table(s) to $path');
        } else {
          stdout.write(source);
        }
        return 0;
      });
}

final class DatabaseCommand extends Command<int> {
  @override
  final name = 'database';
  @override
  final description = 'Database-level operations.';

  DatabaseCommand() {
    addSubcommand(ResetCommand());
  }
}

final class ResetCommand extends Command<int> {
  @override
  final name = 'reset';
  @override
  final description = 'Drop the database and re-run all migrations.';

  @override
  Future<int> run() async {
    final config = DieselConfig.load();
    // SQLite reset = drop the file and re-create. (Per-backend reset can live in
    // the backend later.)
    final path = config.databasePath;
    if (path != ':memory:') {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }
    final connection = openConnection(config);
    try {
      final ran = await MigrationRunner(connection, config.migrationsDir).runPending();
      stdout.writeln('Database reset. Applied ${ran.length} migration(s).');
      return 0;
    } finally {
      await connection.close();
    }
  }
}
