import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/order_mapper.dart';
import 'package:basalt_example/data/mappers/order_item_mapper.dart';
import 'package:basalt_example/data/models/order_item_write.dart';
import 'package:basalt_example/data/models/order_row.dart';
import 'package:basalt_example/data/models/order_write.dart';
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
    return [
      for (final order in orders)
        OrderSummary(
          order: order.toDomain(),
          items: [for (final i in order.items) i.toDomain()],
        ),
    ];
  }

  @override
  Future<OrderSummary?> detail(int id) async {
    final order = await findOrderRow(id).optional(_db);
    if (order == null) return null;
    return OrderSummary(
      order: order.toDomain(),
      items: [for (final i in order.items) i.toDomain()],
    );
  }

  @override
  Future<int> placeOrder(NewOrder order) {
    return _db.transaction((tx) async {
      final now = DateTime.now().millisecondsSinceEpoch;

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
        await tx.execute(
          update(Products.table)
              .value(Products.stock.setExpr(Products.stock - line.quantity))
              .where(Products.id.eq(line.productId)),
        );
      }

      return orderId;
    });
  }

  @override
  Future<void> updateStatus(int orderId, OrderStatus status) async {
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
