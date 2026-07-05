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
