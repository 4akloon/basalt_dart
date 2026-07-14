import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/data/repositories/drift/drift_order_loader.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/loyalty_tier.dart';
import 'package:basalt_example/domain/entities/new_order.dart';
import 'package:basalt_example/domain/entities/order.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/entities/views/order_list_item.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';
import 'package:drift/drift.dart';

/// Drift-backed [OrderRepository].
///
/// The relational reads reuse [loadOrderSummaries] (an explicit two-query join
/// loader — clearer than manager prefetch for this 3-level nesting); writes use
/// drift's generated manager API.
class DriftOrderRepository implements OrderRepository {
  DriftOrderRepository(this._db);

  final ShopDriftDatabase _db;

  @override
  Future<List<OrderListItem>> recent({int limit = 50}) async {
    // One GROUP BY aggregate from queries.drift — header + customer + totals,
    // no line items — newest first.
    final rows = await _db.recentOrders(limit).get();
    return [
      for (final r in rows)
        OrderListItem(
          order: Order(
            id: r.id,
            customerId: r.customerId,
            status: OrderStatus.values.byName(r.status),
            placedAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
            shippingAddressId: r.shippingAddressId,
            customer: Customer(
              id: r.customerPk,
              name: r.customerName,
              email: r.customerEmail,
              tier: LoyaltyTier.values.byName(r.customerTier),
              joinedAt: DateTime.fromMillisecondsSinceEpoch(r.customerCreatedAt),
            ),
          ),
          total: r.total,
          itemCount: r.itemCount,
        ),
    ];
  }

  @override
  Future<OrderSummary?> detail(int id) async {
    final orders = await loadOrderSummaries(_db, orderId: id);
    return orders.isEmpty ? null : orders.first;
  }

  @override
  Future<int> placeOrder(NewOrder order) {
    return _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final orderId = await _db.managers.orders.create(
        (o) => o(
          customerId: order.customerId,
          status: Value(OrderStatus.pending.name),
          shippingAddressId: Value(order.shippingAddressId),
          createdAt: now,
        ),
      );

      for (final line in order.lines) {
        await _db.managers.orderItems.create(
          (o) => o(
            orderId: orderId,
            productId: line.productId,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
          ),
        );
        // Decrement stock with a raw expression update (`stock = stock - ?`) —
        // arithmetic the manager companions can't express.
        await _db.customUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          variables: [
            Variable.withInt(line.quantity),
            Variable.withInt(line.productId),
          ],
          updates: {_db.products},
        );
      }

      return orderId;
    });
  }

  @override
  Future<void> updateStatus(int orderId, OrderStatus status) async {
    await _db.managers.orders
        .filter((f) => f.id.equals(orderId))
        .update((o) => o(status: Value(status.name)));
  }
}
