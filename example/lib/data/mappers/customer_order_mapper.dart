import 'package:basalt_example/data/models/customer_order_row.dart';
import 'package:basalt_example/domain/entities/order.dart';
import 'package:basalt_example/domain/entities/order_item.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';

/// Converts a [CustomerOrderRow] into an [OrderSummary] for the profile screen.
/// The order's customer/shipping address and each line's product are left null —
/// none are shown there; `total` and `itemCount` still fold from the amounts.
extension CustomerOrderRowMapper on CustomerOrderRow {
  OrderSummary toDomain() => OrderSummary(
        order: Order(
          id: id,
          customerId: customerId,
          status: OrderStatus.values.byName(status),
          placedAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
          shippingAddressId: shippingAddressId,
        ),
        items: [
          for (final i in items)
            OrderItem(
              id: i.id,
              orderId: i.orderId,
              productId: i.productId,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
            ),
        ],
      );
}
