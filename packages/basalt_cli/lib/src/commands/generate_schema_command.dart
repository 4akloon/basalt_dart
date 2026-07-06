import 'dart:io';

import '../schema_generator.dart';
import 'db_command.dart';

final class GenerateSchemaCommand extends DbCommand {
  @override
  final name = 'generate-schema';
  @override
  final description =
      'Generate the typed schema (tables and columns only) from the database.';

  @override
  Future<int> run() => withRunner((config, runner) async {
        final tables = await runner.connection.introspect();
        if (tables.isEmpty) {
          stderr.writeln('Warning: no tables found in the database. '
              'Run `basalt migration run` first.');
        }
        final source = SchemaGenerator(typeOverrides: config.typeOverrides)
            .generate(tables);
        final out = File(config.schemaOutput);
        out.parent.createSync(recursive: true);
        out.writeAsStringSync(source);
        stdout.writeln(
          'Wrote ${tables.length} table(s) to ${config.schemaOutput}',
        );
        return 0;
      });
}
