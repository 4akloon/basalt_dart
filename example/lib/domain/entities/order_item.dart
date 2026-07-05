import 'package:basalt_example/domain/entities/product.dart';

/// A single line in an order. [product] is the resolved belongs-to relation
/// (loaded with its category two levels deep).
class OrderItem {
  const OrderItem({
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
  final Product? product;

  /// Extended price for this line.
  double get lineTotal => unitPrice * quantity;
}
