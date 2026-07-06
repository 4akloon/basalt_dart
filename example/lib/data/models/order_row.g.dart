// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [OrderRow] — the object *is* the
/// query (`db.fetch(OrderRowQuery())`).
final class OrderRowQuery extends FoldMappedQuery<OrderRow> {
  OrderRowQuery() : super(_build(), fold, rootPkColumn: Orders.id);

  static Query<Object?> _build() {
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
        );
  }

  /// Reads a [OrderRow] from [r] at [src] (alias-aware, composable).
  static OrderRow fromRow(
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
            : CustomerRowQuery.fromRow(
                r, Customers.table.aliased('${prefix}customer')),
        shippingAddress:
            (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
                ? null
                : r.get(src.col(Orders.shippingAddressId)) == null
                    ? null
                    : AddressRowQuery.fromRow(
                        r,
                        Addresses.table.aliased('${prefix}shippingAddress'),
                        '${prefix}shippingAddress_',
                        (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) -
                            1,
                      ),
      );

  /// Reusable row mapper: `from(t).mapWith(OrderRowQuery.mapper)`.
  static const mapper = RowMapper<OrderRow>(fromRow);

  /// Folds flat JOIN rows into deduplicated parents.
  static List<OrderRow> fold(
    List<RowReader> rows,
  ) {
    final parents = <int, _OrderRowFoldAcc>{};
    for (final r in rows) {
      final pk = r.get(Orders.id);
      final acc = parents.putIfAbsent(
          pk,
          () => _OrderRowFoldAcc(
                fromRow(r, Orders.table, '', 1),
              ));
      if (r.isPresent(OrderItems.table.aliased('items').col(OrderItems.id))) {
        final childPk =
            r.get(OrderItems.table.aliased('items').col(OrderItems.id));
        acc.items.putIfAbsent(
            childPk,
            () => OrderItemRowQuery.fromRow(
                  r,
                  OrderItems.table.aliased('items'),
                  'items_',
                  2,
                ));
      }
    }
    return [for (final a in parents.values) a.build()];
  }
}

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
