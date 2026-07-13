// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_order_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [CustomerOrderRow] — the object *is* the
/// query (`db.fetch(CustomerOrderRowQuery())`).
final class CustomerOrderRowQuery extends FoldMappedQuery<CustomerOrderRow> {
  CustomerOrderRowQuery() : super(_build(), fold, rootPkColumn: Orders.id);

  static Query<Object?> _build() {
    final items = OrderItems.table.aliased('items');
    return from(Orders.table).leftJoin(
      items,
      on: items.col(OrderItems.orderId).eqColumn(Orders.id),
    );
  }

  /// Reads a [CustomerOrderRow] from [r] at [src] (alias-aware, composable).
  static CustomerOrderRow fromRow(
    RowReader r, [
    QuerySource<Orders> src = Orders.table,
  ]) =>
      CustomerOrderRow(
        id: r.get(src.col(Orders.id)),
        customerId: r.get(src.col(Orders.customerId)),
        status: r.get(src.col(Orders.status)),
        createdAt: r.get(src.col(Orders.createdAt)),
        shippingAddressId: r.get(src.col(Orders.shippingAddressId)),
      );

  /// Reusable row mapper: `from(t).mapWith(CustomerOrderRowQuery.mapper)`.
  static const mapper = RowMapper<CustomerOrderRow>(fromRow);

  /// Folds flat JOIN rows into deduplicated parents.
  static List<CustomerOrderRow> fold(
    List<RowReader> rows,
  ) {
    final parents = <int, _CustomerOrderRowFoldAcc>{};
    for (final r in rows) {
      final pk = r.get(Orders.id);
      final acc = parents.putIfAbsent(
          pk,
          () => _CustomerOrderRowFoldAcc(
                CustomerOrderRow(
                  id: r.get(Orders.id),
                  customerId: r.get(Orders.customerId),
                  status: r.get(Orders.status),
                  createdAt: r.get(Orders.createdAt),
                  shippingAddressId: r.get(Orders.shippingAddressId),
                ),
              ));
      if (r.isPresent(OrderItems.table.aliased('items').col(OrderItems.id))) {
        final childPk =
            r.get(OrderItems.table.aliased('items').col(OrderItems.id));
        acc.items.putIfAbsent(
            childPk,
            () => OrderItemAmountRowQuery.fromRow(
                r, OrderItems.table.aliased('items')));
      }
    }
    return [for (final a in parents.values) a.build()];
  }
}

final class _CustomerOrderRowFoldAcc {
  _CustomerOrderRowFoldAcc(this.base);
  final CustomerOrderRow base;
  final items = <int, OrderItemAmountRow>{};

  CustomerOrderRow build() => CustomerOrderRow(
        id: base.id,
        customerId: base.customerId,
        status: base.status,
        createdAt: base.createdAt,
        shippingAddressId: base.shippingAddressId,
        items: [for (final c in items.values) c],
      );
}
