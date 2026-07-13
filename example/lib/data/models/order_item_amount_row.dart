import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'order_item_amount_row.g.dart';

/// Lean read model for `order_items` — the amounts only, **no** `product`
/// relation.
///
/// The full `OrderItemRow` pulls the line's product (and that product's
/// category) two levels deep. The customer profile only needs each line's
/// quantity and price to total an order, so this model skips both joins.
@Queryable(OrderItems.table)
class OrderItemAmountRow {
  const OrderItemAmountRow({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double unitPrice;
}
