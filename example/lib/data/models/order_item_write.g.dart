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

extension OrderItemWriteBatchInsert on Iterable<OrderItemWrite> {
  InsertStatement<OrderItems> toInsert() {
    final rows = [
      for (final row in this)
        [
          OrderItems.orderId.set(row.orderId),
          OrderItems.productId.set(row.productId),
          OrderItems.quantity.set(row.quantity),
          OrderItems.unitPrice.set(row.unitPrice),
        ],
    ];
    if (rows.isEmpty) {
      throw ArgumentError('toInsert() on an empty Iterable<OrderItemWrite>: '
          'an INSERT needs at least one row.');
    }
    return insertInto(OrderItems.table).values(rows);
  }
}
