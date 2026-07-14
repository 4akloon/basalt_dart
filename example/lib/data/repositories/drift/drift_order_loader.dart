import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/data/repositories/drift/drift_mappers.dart';
import 'package:basalt_example/domain/entities/order_item.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';
import 'package:drift/drift.dart';

/// Loads full [OrderSummary]s (order header + customer + shipping address, plus
/// every line item with its product and category) for the drift backend.
///
/// This is the drift analogue of the basalt `OrderRowQuery` fold — one query
/// pulls the order headers, a second bulk-loads all their items (no N+1). It is
/// shared by the order and customer-profile repositories, filtered by
/// [orderId] *or* [customerId], newest first, optionally capped at [limit].
Future<List<OrderSummary>> loadOrderSummaries(
  ShopDriftDatabase db, {
  int? orderId,
  int? customerId,
  int? limit,
}) async {
  final orderQuery = db.select(db.orders).join([
    innerJoin(db.customers, db.customers.id.equalsExp(db.orders.customerId)),
    leftOuterJoin(
      db.addresses,
      db.addresses.id.equalsExp(db.orders.shippingAddressId),
    ),
  ]);
  if (orderId != null) orderQuery.where(db.orders.id.equals(orderId));
  if (customerId != null) {
    orderQuery.where(db.orders.customerId.equals(customerId));
  }
  orderQuery.orderBy([OrderingTerm.desc(db.orders.createdAt)]);
  if (limit != null) orderQuery.limit(limit);

  final orderRows = await orderQuery.get();
  if (orderRows.isEmpty) return const [];

  final ids = [for (final r in orderRows) r.readTable(db.orders).id];
  final itemQuery = db.select(db.orderItems).join([
    innerJoin(db.products, db.products.id.equalsExp(db.orderItems.productId)),
    innerJoin(
      db.categories,
      db.categories.id.equalsExp(db.products.categoryId),
    ),
  ])
    ..where(db.orderItems.orderId.isIn(ids));

  final itemsByOrder = <int, List<OrderItem>>{};
  for (final r in await itemQuery.get()) {
    final item = r.readTable(db.orderItems);
    final product = r.readTable(db.products);
    final category = r.readTable(db.categories);
    (itemsByOrder[item.orderId] ??= []).add(
      orderItemToDomain(
        item,
        product: productToDomain(product, category: categoryToDomain(category)),
      ),
    );
  }

  return [
    for (final r in orderRows)
      OrderSummary(
        order: orderToDomain(
          r.readTable(db.orders),
          customer: customerToDomain(r.readTable(db.customers)),
          shippingAddress: switch (r.readTableOrNull(db.addresses)) {
            final address? => addressToDomain(address),
            null => null,
          },
        ),
        items: itemsByOrder[r.readTable(db.orders).id] ?? const [],
      ),
  ];
}

/// Lean loader for a customer's orders on the profile screen: order headers plus
/// their line-item amounts, with **no** joins (no customer, shipping address,
/// product or category). `total` / `itemCount` still fold from the amounts; the
/// unused relations stay null.
Future<List<OrderSummary>> loadCustomerOrders(
  ShopDriftDatabase db,
  int customerId,
) async {
  final orderRows = await (db.select(db.orders)
        ..where((o) => o.customerId.equals(customerId))
        ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
      .get();
  if (orderRows.isEmpty) return const [];

  final ids = [for (final o in orderRows) o.id];
  final itemRows = await (db.select(db.orderItems)
        ..where((i) => i.orderId.isIn(ids)))
      .get();
  final itemsByOrder = <int, List<OrderItem>>{};
  for (final i in itemRows) {
    (itemsByOrder[i.orderId] ??= []).add(orderItemToDomain(i));
  }

  return [
    for (final o in orderRows)
      OrderSummary(
        order: orderToDomain(o),
        items: itemsByOrder[o.id] ?? const [],
      ),
  ];
}
