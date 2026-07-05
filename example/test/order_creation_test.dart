import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/repositories/order_repository_impl.dart';
import 'package:basalt_example/domain/entities/new_order.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_database.dart';

void main() {
  late Connection db;
  late OrderRepositoryImpl orders;

  setUp(() async {
    db = await openTestDatabase();
    orders = OrderRepositoryImpl(db);
  });

  tearDown(() => db.close());

  Future<int> stockOf(int productId) async {
    final rows = await db.queryRaw(
      'SELECT stock FROM products WHERE id = ?',
      [productId],
    );
    return rows.single['stock'] as int;
  }

  test('placeOrder creates the order + items and decrements stock atomically',
      () async {
    final before = await stockOf(3); // Smartphone X, seeded stock 20.

    final orderId = await orders.placeOrder(
      const NewOrder(
        customerId: 2,
        shippingAddressId: 3,
        lines: [
          NewOrderLine(productId: 3, quantity: 2, unitPrice: 999),
          NewOrderLine(productId: 5, quantity: 1, unitPrice: 149),
        ],
      ),
    );

    expect(orderId, greaterThan(0));
    expect(await stockOf(3), before - 2);

    final detail = await orders.detail(orderId);
    expect(detail, isNotNull);
    expect(detail!.order.status, OrderStatus.pending);
    expect(detail.order.customer?.name, 'Bob Smith');
    // Items carry their product two levels deep (product -> category).
    expect(detail.items, hasLength(2));
    expect(
      detail.items.map((i) => i.product?.category?.name),
      contains('Phones'),
    );
    // total = 2*999 + 1*149
    expect(detail.total, closeTo(2147, 0.001));
  });

  test('updateStatus moves the order to a new state', () async {
    await orders.updateStatus(1, OrderStatus.cancelled);
    final rows = await db.queryRaw(
      'SELECT status FROM ${Orders.table.name} WHERE id = ?',
      [1],
    );
    expect(rows.single['status'], 'cancelled');
  });
}
