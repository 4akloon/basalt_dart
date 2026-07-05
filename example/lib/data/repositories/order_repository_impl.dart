import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/order_mapper.dart';
import 'package:basalt_example/data/models/order_item_write.dart';
import 'package:basalt_example/data/models/order_row.dart';
import 'package:basalt_example/data/models/order_write.dart';
import 'package:basalt_example/data/repositories/order_items_loader.dart';
import 'package:basalt_example/domain/entities/new_order.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';

/// SQLite-backed [OrderRepository].
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._db);

  final Connection _db;

  @override
  Future<List<OrderSummary>> recent({int limit = 50}) async {
    final orders = await orderRowQuery
        .orderBy(Orders.createdAt.desc())
        .limit(limit)
        .load(_db);
    final itemsByOrder =
        await loadOrderItemsByOrder(_db, [for (final o in orders) o.id]);
    return [
      for (final order in orders)
        OrderSummary(
          order: order.toDomain(),
          items: itemsByOrder[order.id] ?? const [],
        ),
    ];
  }

  @override
  Future<OrderSummary?> detail(int id) async {
    final order = await findOrderRow(id).optional(_db);
    if (order == null) return null;
    final items = await loadOrderItemsByOrder(_db, [id]);
    return OrderSummary(
      order: order.toDomain(),
      items: items[id] ?? const [],
    );
  }

  @override
  Future<int> placeOrder(NewOrder order) {
    // Everything below runs atomically: the order header, every line item, and
    // the stock decrements either all commit or all roll back.
    return _db.transaction((tx) async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // INSERT ... RETURNING id — the write model's `toInsert()` omits the id,
      // which SQLite autoincrements and returns.
      final orderId = (await tx.executeReturning(
        OrderWrite(
          customerId: order.customerId,
          status: OrderStatus.pending.name,
          shippingAddressId: order.shippingAddressId,
          createdAt: now,
        ).toInsert().returning([Orders.id]).map((r) => r.get(Orders.id)),
      ))
          .single;

      for (final line in order.lines) {
        await tx.execute(
          OrderItemWrite(
            orderId: orderId,
            productId: line.productId,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
          ).toInsert(),
        );
        // Column-relative arithmetic (`stock = stock - ?`) isn't expressible in
        // the typed builder, so we drop to raw SQL — inside the same tx.
        await tx.executeSql(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [line.quantity, line.productId],
        );
      }

      return orderId;
    });
  }

  @override
  Future<void> updateStatus(int orderId, OrderStatus status) async {
    // Load the current row, rebuild the write model with the new status and
    // persist the whole changeset via `@AsChangeset`'s `toUpdate()`. (A targeted
    // `update(Orders.table).value(Orders.status.set(...))` is also fine; this
    // shows the changeset derive in a load-modify-save flow.)
    final current = await findOrderRow(orderId).optional(_db);
    if (current == null) return;
    await _db.execute(
      OrderWrite(
        customerId: current.customerId,
        status: status.name,
        shippingAddressId: current.shippingAddressId,
        createdAt: current.createdAt,
      ).toUpdate().where(Orders.id.eq(orderId)),
    );
  }
}
