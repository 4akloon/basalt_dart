import 'package:basalt/basalt.dart';
import 'package:basalt_cli/basalt_cli.dart';
import 'package:basalt_example/core/database/seed_data.dart';
import 'package:basalt_sqlite/basalt_sqlite.dart';

/// Opens an in-memory database, applies pending migrations from disk and
/// optionally seeds the demo data.
///
/// Tests run with the package root as the working directory, so the migration
/// files are read straight off disk — no asset bundle needed.
Future<Connection> openTestDatabase({bool seed = true}) async {
  final db = SqliteConnection.memory();
  await MigrationRunner(db, DirectoryMigrationSource('migrations')).runPending();
  if (seed) await SeedData.run(db);
  return db;
}
