import 'migration.dart';

/// Supplies migrations to [MigrationRunner].
///
/// Implementations read from disk, Flutter assets, or any other store. SQL is
/// resolved eagerly in [discover] — fine for the small migration sets typical
/// in app development; a lazy source can be added later if sets grow large.
///
/// {@category migrations}
abstract interface class MigrationSource {
  /// All migrations, ascending by [Migration.version], with SQL already resolved.
  Future<List<Migration>> discover();
}
