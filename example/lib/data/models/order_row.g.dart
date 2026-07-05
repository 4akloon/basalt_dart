// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

OrderRow $OrderRowFromRow(
  RowReader r, [
  QuerySource<Orders> src = Orders.table,
  String prefix = '',
  int budget = 0,
]) =>
    OrderRow(
      id: r.get(src.col(Orders.id)),
      customerId: r.get(src.col(Orders.customerId)),
      status: r.get(src.col(Orders.status)),
      createdAt: r.get(src.col(Orders.createdAt)),
      shippingAddressId: r.get(src.col(Orders.shippingAddressId)),
      customer: (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
          ? null
          : $CustomerRowFromRow(
              r, Customers.table.aliased('${prefix}customer')),
      shippingAddress:
          (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
              ? null
              : r.get(src.col(Orders.shippingAddressId)) == null
                  ? null
                  : $AddressRowFromRow(
                      r,
                      Addresses.table.aliased('${prefix}shippingAddress'),
                      '${prefix}shippingAddress_',
                      (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) - 1,
                    ),
    );

const orderRowMapper = RowMapper<OrderRow>($OrderRowFromRow);

MappedQuery<OrderRow> get orderRowQuery {
  final customer = Customers.table.aliased('customer');
  final shippingAddress = Addresses.table.aliased('shippingAddress');
  return from(Orders.table)
      .innerJoin(
        customer,
        on: Orders.customerId.eqColumn(customer.col(Customers.id)),
      )
      .leftJoin(
        shippingAddress,
        on: Orders.shippingAddressId
            .eqColumn(shippingAddress.col(Addresses.id)),
      )
      .map((r) => $OrderRowFromRow(r, Orders.table, '', 1));
}

/// Fetch the OrderRow with the given primary key.
MappedQuery<OrderRow> findOrderRow(int id) =>
    orderRowQuery.findBy(Orders.id, id);

Future<List<OrderRow>> loadOrderRow(
  Connection db, {
  MappedQuery<OrderRow>? query,
}) async {
  final base = await (query ?? orderRowQuery).load(db);
  if (base.isEmpty) return base;
  final keys = [for (final row in base) row.id];
  final itemsByParent = {
    for (final k in keys) k: <OrderItemRow>[],
  };
  final itemsRows =
      await orderItemRowQuery.where(OrderItems.orderId.isIn(keys)).load(db);
  for (final row in itemsRows) {
    (itemsByParent[row.orderId] ??= []).add(row);
  }
  return [
    for (final row in base)
      OrderRow(
        id: row.id,
        customerId: row.customerId,
        status: row.status,
        createdAt: row.createdAt,
        shippingAddressId: row.shippingAddressId,
        customer: row.customer,
        shippingAddress: row.shippingAddress,
        items: itemsByParent[row.id] ?? const [],
      ),
  ];
}

Future<OrderRow?> findOrderRowById(Connection db, int id) async {
  final rows =
      await loadOrderRow(db, query: orderRowQuery.findBy(Orders.id, id));
  return rows.isEmpty ? null : rows.single;
}
