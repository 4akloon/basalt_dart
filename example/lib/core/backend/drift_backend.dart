import 'dart:io';

import 'package:basalt_example/core/backend/app_backend.dart';
import 'package:basalt_example/core/database/drift/drift_seed.dart';
import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/data/repositories/drift/drift_analytics_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_category_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_customer_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_order_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_product_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_review_repository.dart';
import 'package:basalt_example/domain/repositories/analytics_repository.dart';
import 'package:basalt_example/domain/repositories/category_repository.dart';
import 'package:basalt_example/domain/repositories/customer_repository.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';
import 'package:basalt_example/domain/repositories/product_repository.dart';
import 'package:basalt_example/domain/repositories/review_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// [AppBackend] powered by **drift**, launched from `lib/main_drift.dart`.
///
/// It owns its *own* database file — `drift_shop.db`, separate from basalt's
/// `basalt_shop.db` — opened over the same bundled native SQLite library via
/// `package:drift/native.dart` (no extra native dependency). Repositories come
/// from the drift implementations under `data/repositories/drift/`.
class DriftBackend implements AppBackend {
  @override
  String get label => 'Drift';

  late final ShopDriftDatabase _db;

  @override
  Future<void> open() async {
    _db = ShopDriftDatabase(_openConnection());
    if (await DriftSeed.isEmpty(_db)) {
      await DriftSeed.run(_db);
    }
  }

  /// Opens the drift database file lazily on first query, in the app documents
  /// directory (a sibling of the basalt database — different file, different
  /// instance).
  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'drift_shop.db'));
      return NativeDatabase(file);
    });
  }

  @override
  Future<void> reset() async {
    // Child → parent (foreign-key-safe) order, then clear the autoincrement
    // counters so the re-seed's ids restart at 1 and its `1..N` foreign keys
    // line up again (drift's `autoIncrement()` keeps a `sqlite_sequence` row).
    await _db.transaction(() async {
      await _db.delete(_db.reviews).go();
      await _db.delete(_db.orderItems).go();
      await _db.delete(_db.orders).go();
      await _db.delete(_db.addresses).go();
      await _db.delete(_db.products).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.customers).go();
      await _db.customStatement('DELETE FROM sqlite_sequence');
    });
    await DriftSeed.run(_db);
  }

  @override
  late final CategoryRepository categoryRepository =
      DriftCategoryRepository(_db);

  @override
  late final ProductRepository productRepository = DriftProductRepository(_db);

  @override
  late final CustomerRepository customerRepository =
      DriftCustomerRepository(_db);

  @override
  late final OrderRepository orderRepository = DriftOrderRepository(_db);

  @override
  late final ReviewRepository reviewRepository = DriftReviewRepository(_db);

  @override
  late final AnalyticsRepository analyticsRepository =
      DriftAnalyticsRepository(_db);
}
