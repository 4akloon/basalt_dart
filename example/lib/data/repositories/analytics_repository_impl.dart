import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/product_mapper.dart';
import 'package:basalt_example/data/models/product_row.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/loyalty_tier.dart';
import 'package:basalt_example/domain/entities/views/analytics.dart';
import 'package:basalt_example/domain/repositories/analytics_repository.dart';

/// SQLite-backed [AnalyticsRepository]. Mixes typed aggregate queries with the
/// raw-SQL escape hatch for rollups that multiply two columns (`quantity *
/// unit_price`), which the typed aggregate API doesn't express.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._db);

  final Connection _db;

  @override
  Future<List<CategoryRevenue>> revenueByCategory() async {
    final rows = await _db.queryRaw('''
      SELECT c.name                          AS category_name,
             SUM(oi.quantity * oi.unit_price) AS revenue,
             SUM(oi.quantity)                 AS units_sold
      FROM order_items oi
      JOIN products   p ON p.id = oi.product_id
      JOIN categories c ON c.id = p.category_id
      GROUP BY c.id
      ORDER BY revenue DESC
    ''');
    return [
      for (final row in rows)
        CategoryRevenue(
          categoryName: row['category_name'] as String,
          revenue: (row['revenue'] as num).toDouble(),
          unitsSold: (row['units_sold'] as num).toInt(),
        ),
    ];
  }

  @override
  Future<List<TopCustomer>> topCustomers({int limit = 5}) async {
    final rows = await _db.queryRaw('''
      SELECT cu.id                            AS id,
             cu.name                          AS name,
             cu.email                         AS email,
             cu.loyalty_tier                  AS loyalty_tier,
             cu.created_at                    AS created_at,
             SUM(oi.quantity * oi.unit_price) AS total_spent,
             COUNT(DISTINCT o.id)             AS order_count
      FROM customers   cu
      JOIN orders      o  ON o.customer_id = cu.id
      JOIN order_items oi ON oi.order_id = o.id
      GROUP BY cu.id
      ORDER BY total_spent DESC
      LIMIT ?
    ''', [limit]);
    return [
      for (final row in rows)
        TopCustomer(
          customer: Customer(
            id: (row['id'] as num).toInt(),
            name: row['name'] as String,
            email: row['email'] as String,
            tier: LoyaltyTier.values.byName(row['loyalty_tier'] as String),
            joinedAt: DateTime.fromMillisecondsSinceEpoch(
              (row['created_at'] as num).toInt(),
            ),
          ),
          totalSpent: (row['total_spent'] as num).toDouble(),
          orderCount: (row['order_count'] as num).toInt(),
        ),
    ];
  }

  @override
  Future<List<LowStockProduct>> lowStock({int threshold = 5}) async {
    // Typed query — no raw SQL needed here.
    final rows = await productRowQuery
        .filter(Products.isActive.eq(1))
        .filter(Products.stock.le(threshold))
        .orderBy(Products.stock.asc())
        .load(_db);
    return [
      for (final row in rows)
        LowStockProduct(product: row.toDomain(), stock: row.stock),
    ];
  }
}
