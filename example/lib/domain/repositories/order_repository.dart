import 'package:basalt_example/domain/entities/new_order.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';

/// Read/write access to orders.
abstract interface class OrderRepository {
  /// Most recent orders (header + customer), newest first.
  Future<List<OrderSummary>> recent({int limit = 50});

  /// A single order with its line items (each item carrying its product), or
  /// null if not found.
  Future<OrderSummary?> detail(int id);

  /// Creates an order and its line items in one transaction, decrementing the
  /// purchased products' stock. Returns the new order id.
  Future<int> placeOrder(NewOrder order);

  /// Moves an order to a new [status].
  Future<void> updateStatus(int orderId, OrderStatus status);
}
