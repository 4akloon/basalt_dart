import 'package:basalt_example/data/mappers/product_mapper.dart';
import 'package:basalt_example/data/models/order_item_row.dart';
import 'package:basalt_example/domain/entities/order_item.dart';

/// Converts an [OrderItemRow] into a domain [OrderItem], mapping the nested
/// product (loaded two levels deep, with its category).
extension OrderItemRowMapper on OrderItemRow {
  OrderItem toDomain() => OrderItem(
        id: id,
        orderId: orderId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        product: product?.toDomain(),
      );
}
