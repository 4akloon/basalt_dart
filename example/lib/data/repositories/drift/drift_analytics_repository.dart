import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/data/repositories/drift/drift_lookups.dart';
import 'package:basalt_example/data/repositories/drift/drift_mappers.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/loyalty_tier.dart';
import 'package:basalt_example/domain/entities/views/analytics.dart';
import 'package:basalt_example/domain/repositories/analytics_repository.dart';
import 'package:drift/drift.dart';

/// Drift-backed [AnalyticsRepository].
///
/// The two roll-ups are generated from the SQL in `queries.drift` (typed
/// `revenueByCategory()` / `topCustomers()` methods with generated result
/// classes) — the drift counterpart of basalt's typed `sum(...)` /
/// `countDistinct(...)` `@Queryable` aggregate views. `lowStock` is a plain
/// manager-API filter.
class DriftAnalyticsRepository implements AnalyticsRepository {
  DriftAnalyticsRepository(this._db);

  final ShopDriftDatabase _db;

  @override
  Future<List<CategoryRevenue>> revenueByCategory() async {
    final rows = await _db.revenueByCategory().get();
    return [
      for (final r in rows)
        CategoryRevenue(
          categoryName: r.categoryName,
          revenue: r.revenue ?? 0,
          unitsSold: r.unitsSold ?? 0,
        ),
    ];
  }

  @override
  Future<List<TopCustomer>> topCustomers({int limit = 5}) async {
    final rows = await _db.topCustomers(limit).get();
    return [
      for (final r in rows)
        TopCustomer(
          customer: Customer(
            id: r.id,
            name: r.name,
            email: r.email,
            tier: LoyaltyTier.values.byName(r.loyaltyTier),
            joinedAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
          ),
          totalSpent: r.totalSpent ?? 0,
          orderCount: r.orderCount,
        ),
    ];
  }

  @override
  Future<List<LowStockProduct>> lowStock({int threshold = 5}) async {
    final products = await _db.managers.products
        .filter((f) =>
            f.isActive.equals(1) & f.stock.isSmallerOrEqualTo(threshold))
        .orderBy((o) => o.stock.asc())
        .get();

    final categories = await loadCategoryIndex(_db);
    return [
      for (final p in products)
        LowStockProduct(
          product: productToDomain(p, category: categories[p.categoryId]),
          stock: p.stock,
        ),
    ];
  }
}
