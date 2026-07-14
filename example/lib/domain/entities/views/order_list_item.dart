import 'package:basalt_example/domain/entities/order.dart';

/// A row in the orders list — an [order] header (with its customer) plus the
/// pre-aggregated [total] and [itemCount].
///
/// Unlike `OrderSummary`, this does **not** carry the individual line items: the
/// list screen only shows the count and the total, so both backends compute them
/// with a single `GROUP BY` aggregate instead of loading (and folding) every
/// line item, its product and category.
class OrderListItem {
  const OrderListItem({
    required this.order,
    required this.total,
    required this.itemCount,
  });

  final Order order;
  final double total;
  final int itemCount;
}
