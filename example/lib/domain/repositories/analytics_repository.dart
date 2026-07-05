import 'package:basalt_example/domain/entities/views/analytics.dart';

/// Read access to shop analytics — aggregate rollups over orders and stock.
abstract interface class AnalyticsRepository {
  /// Revenue and units sold per category (typed `GROUP BY` aggregate).
  Future<List<CategoryRevenue>> revenueByCategory();

  /// Top [limit] customers by lifetime spend (raw-SQL aggregate).
  Future<List<TopCustomer>> topCustomers({int limit = 5});

  /// Products at or below the reorder [threshold].
  Future<List<LowStockProduct>> lowStock({int threshold = 5});
}
