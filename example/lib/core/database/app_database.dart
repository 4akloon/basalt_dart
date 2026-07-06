import 'package:basalt/basalt.dart';
import 'package:basalt/migration.dart';
import 'package:basalt_example/core/database/asset_migration_source.dart';
import 'package:basalt_example/core/database/seed_data.dart';
import 'package:basalt_example/core/di/injector.dart';
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
    final path = p.join(dir.path, fileName);
    final db = SqliteConnection.open(path);

    await MigrationRunner(db, AssetMigrationSource()).runPending();
    if (await SeedData.isEmpty(db)) {
      await SeedData.run(db);
    }
    return db;
  }

  /// Tables to clear on [reset], in child→parent (foreign-key-safe) order.
  static const _seededTables = [
    'reviews',
    'order_items',
    'orders',
    'addresses',
    'products',
    'categories',
    'customers',
  ];

  /// **Dev-only.** Deletes all demo data and re-seeds it, reusing the open
  /// connection (migrations stay applied). Row ids restart at 1 — an
  /// `INTEGER PRIMARY KEY` without `AUTOINCREMENT` reuses ROWID 1 on an empty
  /// table — so the seed's `1..N` foreign keys line up again. Backs the debug
  /// "Reset & reseed" action; resolves the [Connection] from the locator so the
  /// presentation layer needn't touch `basalt`.
  static Future<void> reset() async {
    final db = getIt<Connection>();
    await db.transaction((tx) async {
      for (final table in _seededTables) {
        await tx.executeSql('DELETE FROM $table');
      }
    });
    await SeedData.run(db);
  }
}
