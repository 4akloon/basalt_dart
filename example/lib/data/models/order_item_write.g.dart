// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_write.dart';

// **************************************************************************
// InsertableGenerator
// **************************************************************************

extension OrderItemWriteInsert on OrderItemWrite {
  InsertStatement<OrderItems> toInsert() => insertInto(OrderItems.table)
      .value(OrderItems.orderId.set(orderId))
      .value(OrderItems.productId.set(productId))
      .value(OrderItems.quantity.set(quantity))
      .value(OrderItems.unitPrice.set(unitPrice));
}
