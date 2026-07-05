import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'order_item_write.g.dart';

/// **Write** model for `order_items`.
@Insertable(OrderItems.table)
class OrderItemWrite {
  const OrderItemWrite({
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final int orderId;
  final int productId;
  final int quantity;
  final double unitPrice;
}
