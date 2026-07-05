import 'dart:io';

import '../schema_generator.dart';
import 'db_command.dart';

final class PrintSchemaCommand extends DbCommand {
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
              'Run `basalt migration run` first.');
        }
        final source = const SchemaGenerator().generate(tables);
        if (argResults?['output'] case final String path) {
          File(path).writeAsStringSync(source);
          stdout.writeln('Wrote ${tables.length} table(s) to $path');
        } else {
          stdout.write(source);
        }
        return 0;
      });
}
