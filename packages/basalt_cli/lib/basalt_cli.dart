/// CLI library for the Basalt Dart ORM. The `basalt` executable is a thin
/// wrapper over [CliRunner]; the migration engine ([MigrationRunner]) lives in
/// `package:basalt/migration.dart` and is re-exported here for convenience.
///
/// {@category getting-started}
library;

export 'package:basalt/migration.dart';

export 'src/cli_runner.dart';
export 'src/config.dart';
export 'src/connection_factory.dart';
export 'src/directory_migration_source.dart';
export 'src/migration_scaffolder.dart';
export 'src/schema_generator.dart';
export 'src/schema_type_overrides.dart';
