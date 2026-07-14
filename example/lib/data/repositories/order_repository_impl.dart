import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/customer_mapper.dart';
import 'package:basalt_example/data/mappers/order_mapper.dart';
import 'package:basalt_example/data/mappers/order_item_mapper.dart';
import 'package:basalt_example/data/models/customer_row.dart';
import 'package:basalt_example/data/models/order_item_write.dart';
import 'package:basalt_example/data/models/order_row.dart';
import 'package:basalt_example/data/models/order_write.dart';
import 'package:basalt_example/domain/entities/new_order.dart';
import 'package:basalt_example/domain/entities/order.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/entities/views/order_list_item.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';

/// SQLite-backed [OrderRepository].
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._db);

  final Connection _db;

  @override
  Future<List<OrderListItem>> recent({int limit = 50}) {
    // A single GROUP BY aggregate: order header + customer + summed totals, with
    // no line-item/product/category joins (the list doesn't render them). Being
    // a plain select — not a `@HasMany` fold with a parent-limit subquery — the
    // `ORDER BY created_at DESC` is honoured, so this is genuinely newest-first.
    final Aggregate<double?> total =
        sum(OrderItems.quantity * OrderItems.unitPrice, as: 'total');
    final Aggregate<int?> itemCount =
        sum(OrderItems.quantity, as: 'item_count');
    return _db.fetch(
      from(Orders.table)
          .innerJoin(Customers.table, onFk: Orders.customerId)
          .leftJoin(OrderItems.table,
              on: OrderItems.orderId.eqColumn(Orders.id))
          .select([
            Orders.id,
            Orders.customerId,
            Orders.status,
            Orders.shippingAddressId,
            Orders.createdAt,
            Customers.id,
            Customers.name,
            Customers.email,
            Customers.loyaltyTier,
            Customers.createdAt,
            total,
            itemCount,
          ])
          .groupBy([
            Orders.id,
            Orders.customerId,
            Orders.status,
            Orders.shippingAddressId,
            Orders.createdAt,
            Customers.id,
            Customers.name,
            Customers.email,
            Customers.loyaltyTier,
            Customers.createdAt,
          ])
          .orderBy(Orders.createdAt.desc())
          .limit(limit)
          .map((r) => OrderListItem(
                order: Order(
                  id: r.get(Orders.id),
                  customerId: r.get(Orders.customerId),
                  status: OrderStatus.values.byName(r.get(Orders.status)),
                  placedAt: DateTime.fromMillisecondsSinceEpoch(
                      r.get(Orders.createdAt)),
                  shippingAddressId: r.get(Orders.shippingAddressId),
                  customer: CustomerRowQuery.fromRow(r).toDomain(),
                ),
                total: r.get(total) ?? 0,
                itemCount: r.get(itemCount) ?? 0,
              )),
    );
  }

  @override
  Future<OrderSummary?> detail(int id) async {
    final order = await OrderRowQuery().findBy(Orders.id, id).optional(_db);
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
    final current = await OrderRowQuery().findBy(Orders.id, orderId).optional(_db);
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
