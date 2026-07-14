import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/order_item_amount_row.dart';

part 'customer_order_row.g.dart';

/// Lean read model for a customer's orders on the profile screen: the order
/// header plus its line-item amounts, and **nothing else**.
///
/// The full `OrderRow` joins the order's customer and shipping address, and each
/// line's product + category. The profile already knows the customer, and its
/// order rows show only the item count, total and status — so this model drops
/// all four of those joins, leaving just `orders` + `order_items`.
@Queryable(Orders.table)
class CustomerOrderRow {
  const CustomerOrderRow({
    required this.id,
    required this.customerId,
    required this.status,
    required this.createdAt,
    this.shippingAddressId,
    this.items = const [],
  });

  final int id;
  final int customerId;
  final String status;
  final int createdAt;
  final int? shippingAddressId;

  @HasMany(OrderItems.orderId)
  final List<OrderItemAmountRow> items;
}
