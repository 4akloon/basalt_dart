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

final class _OrderRowFoldAcc {
  _OrderRowFoldAcc(this.base);
  final OrderRow base;
  final items = <int, OrderItemRow>{};

  OrderRow build() => OrderRow(
        id: base.id,
        customerId: base.customerId,
        status: base.status,
        createdAt: base.createdAt,
        shippingAddressId: base.shippingAddressId,
        customer: base.customer,
        shippingAddress: base.shippingAddress,
        items: [for (final c in items.values) c],
      );
}

List<OrderRow> $OrderRowFold(
  List<RowReader> rows,
) {
  final parents = <int, _OrderRowFoldAcc>{};
  for (final r in rows) {
    final pk = r.get(Orders.id);
    final acc = parents.putIfAbsent(
        pk,
        () => _OrderRowFoldAcc(
              $OrderRowFromRow(r, Orders.table, '', 1),
            ));
    if (r.isPresent(OrderItems.table.aliased('items').col(OrderItems.id))) {
      final childPk =
          r.get(OrderItems.table.aliased('items').col(OrderItems.id));
      acc.items.putIfAbsent(
          childPk,
          () => $OrderItemRowFromRow(
                r,
                OrderItems.table.aliased('items'),
                'items_',
                2,
              ));
    }
  }
  return [for (final a in parents.values) a.build()];
}

FoldMappedQuery<OrderRow> get orderRowQuery {
  final customer = Customers.table.aliased('customer');
  final shippingAddress = Addresses.table.aliased('shippingAddress');
  final items = OrderItems.table.aliased('items');
  final itemsProduct = Products.table.aliased('items_product');
  final itemsProductCategory =
      Categories.table.aliased('items_product_category');
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
      .leftJoin(
        items,
        on: items.col(OrderItems.orderId).eqColumn(Orders.id),
      )
      .leftJoin(
        itemsProduct,
        on: items
            .col(OrderItems.productId)
            .eqColumn(itemsProduct.col(Products.id)),
      )
      .leftJoin(
        itemsProductCategory,
        on: itemsProduct
            .col(Products.categoryId)
            .eqColumn(itemsProductCategory.col(Categories.id)),
      )
      .mapFold($OrderRowFold)
      .withRootPk(Orders.id);
}

/// Fetch the OrderRow with the given primary key.
FoldMappedQuery<OrderRow> findOrderRow(int id) =>
    orderRowQuery.findBy(Orders.id, id);
