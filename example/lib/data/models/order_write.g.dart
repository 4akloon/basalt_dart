// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_write.dart';

// **************************************************************************
// InsertableGenerator
// **************************************************************************

extension OrderWriteInsert on OrderWrite {
  InsertStatement<Orders> toInsert() => insertInto(Orders.table)
      .value(Orders.customerId.set(customerId))
      .value(Orders.status.set(status))
      .value(Orders.createdAt.set(createdAt))
      .value(Orders.shippingAddressId.set(shippingAddressId));
}

extension OrderWriteBatchInsert on Iterable<OrderWrite> {
  InsertStatement<Orders> toInsert() {
    final rows = [
      for (final row in this)
        [
          Orders.customerId.set(row.customerId),
          Orders.status.set(row.status),
          Orders.createdAt.set(row.createdAt),
          Orders.shippingAddressId.set(row.shippingAddressId),
        ],
    ];
    if (rows.isEmpty) {
      throw ArgumentError('toInsert() on an empty Iterable<OrderWrite>: '
          'an INSERT needs at least one row.');
    }
    return insertInto(Orders.table).values(rows);
  }
}

// **************************************************************************
// AsChangesetGenerator
// **************************************************************************

extension OrderWriteChangeset on OrderWrite {
  UpdateStatement<Orders> toUpdate() => update(Orders.table)
      .value(Orders.customerId.set(customerId))
      .value(Orders.status.set(status))
      .value(Orders.createdAt.set(createdAt))
      .value(Orders.shippingAddressId.set(shippingAddressId));
}
