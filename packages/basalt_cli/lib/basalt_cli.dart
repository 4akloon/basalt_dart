/// CLI library for the Basalt Dart ORM. The `basalt` executable is a thin
/// bootstrapper ([Bootstrapper]) that generates and runs an entrypoint
/// calling [runBasalt] with the configured backend adapter; the migration
/// engine ([MigrationRunner]) lives in `package:basalt/migration.dart` and is
/// re-exported here for convenience, as is the adapter contract from
/// `package:basalt/tooling.dart`.
///
/// {@category getting-started}
library;

export 'package:basalt/migration.dart';
export 'package:basalt/tooling.dart';

export 'src/bootstrap/backend_resolver.dart';
export 'src/bootstrap/bootstrapper.dart';
export 'src/bootstrap/entrypoint_generator.dart';
export 'src/cli_runner.dart';
export 'src/config.dart';
export 'src/directory_migration_source.dart';
export 'src/migration_scaffolder.dart';
export 'src/run_basalt.dart';
export 'src/schema_generator.dart';
