import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/order_item_mapper.dart';
import 'package:basalt_example/data/models/order_item_row.dart';
import 'package:basalt_example/domain/entities/order_item.dart';

/// Loads the line items for every order in [orderIds] in a **single** query
/// (each item carrying its product and that product's category, via the
/// `depth: 2` relation), then groups them by `order_id` in memory. Avoids the
/// N+1 that a per-order fetch would cause.
///
/// Shared by the order and customer repositories.
Future<Map<int, List<OrderItem>>> loadOrderItemsByOrder(
  Connection db,
  List<int> orderIds,
) async {
  final grouped = <int, List<OrderItem>>{for (final id in orderIds) id: []};
  if (orderIds.isEmpty) return grouped;

  final rows = await orderItemRowQuery
      .where(OrderItems.orderId.isIn(orderIds))
      .load(db);
  for (final row in rows) {
    (grouped[row.orderId] ??= []).add(row.toDomain());
  }
  return grouped;
}
