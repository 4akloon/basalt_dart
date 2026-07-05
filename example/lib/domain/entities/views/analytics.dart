import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/product.dart';

/// Revenue and units sold rolled up per category — a `GROUP BY` aggregate over
/// order items joined to products.
class CategoryRevenue {
  const CategoryRevenue({
    required this.categoryName,
    required this.revenue,
    required this.unitsSold,
  });

  final String categoryName;
  final double revenue;
  final int unitsSold;
}

/// A customer ranked by lifetime spend — computed with a raw-SQL aggregate that
/// sums `quantity * unit_price` across their orders.
class TopCustomer {
  const TopCustomer({
    required this.customer,
    required this.totalSpent,
    required this.orderCount,
  });

  final Customer customer;
  final double totalSpent;
  final int orderCount;
}

/// A product whose stock has fallen to or below the reorder threshold.
class LowStockProduct {
  const LowStockProduct({
    required this.product,
    required this.stock,
  });

  final Product product;
  final int stock;
}
