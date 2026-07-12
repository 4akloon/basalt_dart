import 'dart:io';

import '../schema_generator.dart';
import 'db_command.dart';

final class GenerateSchemaCommand extends DbCommand {
  GenerateSchemaCommand(super.adapter);

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
        // User `types:` overrides win over the adapter's presets; the native
        // preset tier joins in (over the portable tier) only on opt-in.
        final presets = config.nativeTypes
            ? adapter.nativeTypeOverrides.overlay(adapter.typeOverrides)
            : adapter.typeOverrides;
        final source = SchemaGenerator(
          typeOverrides: config.typeOverrides.overlay(presets),
        ).generate(tables);
        final out = File(config.schemaOutput);
        out.parent.createSync(recursive: true);
        out.writeAsStringSync(source);
        stdout.writeln(
          'Wrote ${tables.length} table(s) to ${config.schemaOutput}',
        );
        return 0;
      });
}
