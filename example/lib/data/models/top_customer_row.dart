import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'top_customer_row.g.dart';

/// Aggregate read model: customers ranked by lifetime spend.
@Queryable(
  Customers.table,
  joins: [Orders.customerId, OrderItems.orderId],
  orderBy: TopCustomerRow._totalSpent,
  orderDesc: true,
)
class TopCustomerRow {
  const TopCustomerRow({
    required this.id,
    required this.name,
    required this.email,
    required this.loyaltyTier,
    required this.createdAt,
    required this.totalSpent,
    required this.orderCount,
  });

  final int id;
  final String name;
  final String email;
  final String loyaltyTier;
  final int createdAt;

  @Agg(TopCustomerRow._totalSpent)
  final double totalSpent;

  @Agg(TopCustomerRow._orderCount)
  final int orderCount;

  static Aggregate<double?> _totalSpent() => sum(
        OrderItems.quantity * OrderItems.unitPrice,
        as: 'total_spent',
      );

  static Aggregate<int> _orderCount() =>
      countDistinct(Orders.id, as: 'order_count');
}
