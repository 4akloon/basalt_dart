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
