/// CLI library for the Diesel Dart ORM. The `diesel_dart` executable is a thin
/// wrapper over [buildRunner]; the migration engine ([MigrationRunner]) is
/// exposed for embedding and testing.
library;

export 'src/config.dart';
export 'src/database.dart';
export 'src/migrations.dart';
export 'src/runner.dart';
export 'src/schema_gen.dart';
