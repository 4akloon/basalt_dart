import 'dart:io';

import 'package:args/command_runner.dart';

import '../config.dart';
import '../migration_scaffolder.dart';

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
    final config = BasaltConfig.load(
      configPath: globalResults?['config'] as String? ?? 'basalt.yaml',
    );
    final dir =
        const MigrationScaffolder().scaffold(rest.first, config.migrationsDir);
    stdout.writeln('Created $dir');
    return 0;
  }
}
