import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/product_row.dart';

part 'order_item_row.g.dart';

/// **Read** model for `order_items` — the orders↔products junction (write model:
/// `OrderItemWrite`).
///
/// The `@Relation` on [product] uses `depth: 2`, so `orderItemRowQuery` unrolls
/// two levels of joins: the line's [product] **and** that product's category
/// (`ProductRow` itself declares a `category` relation). One query, fully
/// nested.
@Queryable(OrderItems.table)
class OrderItemRow {
  const OrderItemRow({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.product,
  });

  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double unitPrice;

  @Relation(OrderItems.productId, depth: 2)
  final ProductRow? product;
}
