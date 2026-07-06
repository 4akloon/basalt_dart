import 'package:basalt/basalt.dart';
import 'package:basalt_example/data/mappers/analytics_mapper.dart';
import 'package:basalt_example/data/mappers/product_mapper.dart';
import 'package:basalt_example/data/models/category_revenue_row.dart';
import 'package:basalt_example/data/models/product_row.dart';
import 'package:basalt_example/data/models/top_customer_row.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/domain/entities/views/analytics.dart';
import 'package:basalt_example/domain/repositories/analytics_repository.dart';

/// SQLite-backed [AnalyticsRepository] using generated aggregate `@Queryable` views.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._db);

  final Connection _db;

  @override
  Future<List<CategoryRevenue>> revenueByCategory() async {
    final rows = await CategoryRevenueRowQuery().load(_db);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<List<TopCustomer>> topCustomers({int limit = 5}) async {
    final rows = await TopCustomerRowQuery().limit(limit).load(_db);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<List<LowStockProduct>> lowStock({int threshold = 5}) async {
    final rows = await ProductRowQuery()
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
