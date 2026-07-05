import 'package:basalt_example/domain/entities/order.dart';
import 'package:basalt_example/domain/entities/order_item.dart';

/// An order together with its line items — the order-detail view. [total] is
/// computed from the lines.
class OrderSummary {
  const OrderSummary({
    required this.order,
    required this.items,
  });

  final Order order;
  final List<OrderItem> items;

  double get total =>
      items.fold(0, (sum, item) => sum + item.lineTotal);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
