import 'package:basalt/basalt.dart';
import 'package:basalt/migration.dart';
import 'package:basalt_example/core/database/asset_migration_source.dart';
import 'package:basalt_example/core/database/seed_data.dart';
import 'package:basalt_sqlite/basalt_sqlite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the on-device database, applies pending migrations from bundled assets
/// and seeds demo data on first launch.
class AppDatabase {
  const AppDatabase._();

  /// Database file name inside the app documents directory.
  static const fileName = 'basalt_shop.db';

  /// Opens (creating if needed) the shop database and returns a ready-to-use
  /// [Connection]. Idempotent: migrations only apply once, seed only runs when
  /// the database is empty.
  static Future<Connection> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final db = SqliteConnection.open(p.join(dir.path, fileName));

    await MigrationRunner(db, AssetMigrationSource()).runPending();
    if (await SeedData.isEmpty(db)) {
      await SeedData.run(db);
    }
    return db;
  }
}
