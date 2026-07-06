// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_profile_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [CustomerProfileRow] — the object *is* the
/// query (`db.fetch(CustomerProfileRowQuery())`).
final class CustomerProfileRowQuery
    extends FoldMappedQuery<CustomerProfileRow> {
  CustomerProfileRowQuery() : super(_build(), fold, rootPkColumn: Customers.id);

  static Query<Object?> _build() {
    final addresses = Addresses.table.aliased('addresses');
    final addressesCustomer = Customers.table.aliased('addresses_customer');
    final orders = Orders.table.aliased('orders');
    final ordersCustomer = Customers.table.aliased('orders_customer');
    final ordersShippingAddress =
        Addresses.table.aliased('orders_shippingAddress');
    final ordersItems = OrderItems.table.aliased('orders_items');
    final ordersItemsProduct = Products.table.aliased('orders_items_product');
    final ordersItemsProductCategory =
        Categories.table.aliased('orders_items_product_category');
    return from(Customers.table)
        .leftJoin(
          addresses,
          on: addresses.col(Addresses.customerId).eqColumn(Customers.id),
        )
        .leftJoin(
          addressesCustomer,
          on: addresses
              .col(Addresses.customerId)
              .eqColumn(addressesCustomer.col(Customers.id)),
        )
        .leftJoin(
          orders,
          on: orders.col(Orders.customerId).eqColumn(Customers.id),
        )
        .leftJoin(
          ordersCustomer,
          on: orders
              .col(Orders.customerId)
              .eqColumn(ordersCustomer.col(Customers.id)),
        )
        .leftJoin(
          ordersShippingAddress,
          on: orders
              .col(Orders.shippingAddressId)
              .eqColumn(ordersShippingAddress.col(Addresses.id)),
        )
        .leftJoin(
          ordersItems,
          on: ordersItems
              .col(OrderItems.orderId)
              .eqColumn(orders.col(Orders.id)),
        )
        .leftJoin(
          ordersItemsProduct,
          on: ordersItems
              .col(OrderItems.productId)
              .eqColumn(ordersItemsProduct.col(Products.id)),
        )
        .leftJoin(
          ordersItemsProductCategory,
          on: ordersItemsProduct
              .col(Products.categoryId)
              .eqColumn(ordersItemsProductCategory.col(Categories.id)),
        );
  }

  /// Reads a [CustomerProfileRow] from [r] at [src] (alias-aware, composable).
  static CustomerProfileRow fromRow(
    RowReader r, [
    QuerySource<Customers> src = Customers.table,
  ]) =>
      CustomerProfileRow(
        id: r.get(src.col(Customers.id)),
        name: r.get(src.col(Customers.name)),
        email: r.get(src.col(Customers.email)),
        loyaltyTier: r.get(src.col(Customers.loyaltyTier)),
        createdAt: r.get(src.col(Customers.createdAt)),
      );

  /// Reusable row mapper: `from(t).mapWith(CustomerProfileRowQuery.mapper)`.
  static const mapper = RowMapper<CustomerProfileRow>(fromRow);

  /// Folds flat JOIN rows into deduplicated parents.
  static List<CustomerProfileRow> fold(
    List<RowReader> rows,
  ) {
    final parents = <int, _CustomerProfileRowFoldAcc>{};
    for (final r in rows) {
      final pk = r.get(Customers.id);
      final acc = parents.putIfAbsent(
          pk,
          () => _CustomerProfileRowFoldAcc(
                CustomerProfileRow(
                  id: r.get(Customers.id),
                  name: r.get(Customers.name),
                  email: r.get(Customers.email),
                  loyaltyTier: r.get(Customers.loyaltyTier),
                  createdAt: r.get(Customers.createdAt),
                ),
              ));
      if (r.isPresent(Addresses.table.aliased('addresses').col(Addresses.id))) {
        final childPk =
            r.get(Addresses.table.aliased('addresses').col(Addresses.id));
        acc.addresses.putIfAbsent(
            childPk,
            () => AddressRowQuery.fromRow(
                  r,
                  Addresses.table.aliased('addresses'),
                  'addresses_',
                  1,
                ));
      }
      if (r.isPresent(Orders.table.aliased('orders').col(Orders.id))) {
        final childPk = r.get(Orders.table.aliased('orders').col(Orders.id));
        final childAcc = acc.orders.putIfAbsent(
            childPk,
            () => _OrderRowFoldAcc(OrderRowQuery.fromRow(
                  r,
                  Orders.table.aliased('orders'),
                  'orders_',
                  1,
                )));
        if (r.isPresent(
            OrderItems.table.aliased('orders_items').col(OrderItems.id))) {
          final childPk = r
              .get(OrderItems.table.aliased('orders_items').col(OrderItems.id));
          childAcc.items.putIfAbsent(
              childPk,
              () => OrderItemRowQuery.fromRow(
                    r,
                    OrderItems.table.aliased('orders_items'),
                    'orders_items_',
                    2,
                  ));
        }
      }
    }
    return [for (final a in parents.values) a.build()];
  }
}

final class _CustomerProfileRowFoldAcc {
  _CustomerProfileRowFoldAcc(this.base);
  final CustomerProfileRow base;
  final addresses = <int, AddressRow>{};
  final orders = <int, _OrderRowFoldAcc>{};

  CustomerProfileRow build() => CustomerProfileRow(
        id: base.id,
        name: base.name,
        email: base.email,
        loyaltyTier: base.loyaltyTier,
        createdAt: base.createdAt,
        addresses: [for (final c in addresses.values) c],
        orders: [for (final c in orders.values) c.build()],
      );
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
