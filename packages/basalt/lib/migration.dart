/// Schema migration engine for the Basalt Dart ORM.
///
/// A second entrypoint of `package:basalt`, kept separate from
/// `package:basalt/basalt.dart` so plain ORM users don't pull in migration
/// types unless they need them. Use [MigrationRunner] with a [MigrationSource]
/// implementation (disk, assets, or custom) to apply versioned SQL files and
/// track them in `__basalt_schema_migrations`.
library;

export 'src/migration/migration.dart';
export 'src/migration/migration_ddl.dart';
export 'src/migration/migration_runner.dart';
export 'src/migration/migration_source.dart';
export 'src/migration/migration_status.dart';
