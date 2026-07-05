import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'category_revenue_row.g.dart';

/// Aggregate read model: revenue rolled up per category.
@Queryable(
  OrderItems.table,
  joins: [OrderItems.productId, Products.categoryId],
  orderBy: CategoryRevenueRow._revenue,
  orderDesc: true,
)
class CategoryRevenueRow {
  const CategoryRevenueRow({
    required this.categoryName,
    required this.revenue,
    required this.unitsSold,
  });

  @Column(Categories.name)
  final String categoryName;

  @Agg(CategoryRevenueRow._revenue)
  final double revenue;

  @Agg(CategoryRevenueRow._unitsSold)
  final int unitsSold;

  static Aggregate<double?> _revenue() =>
      sum(OrderItems.quantity * OrderItems.unitPrice, as: 'revenue');

  static Aggregate<int?> _unitsSold() =>
      sum(OrderItems.quantity, as: 'units_sold');
}
