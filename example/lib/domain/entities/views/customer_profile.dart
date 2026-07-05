import 'package:basalt_example/domain/entities/address.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';

/// A customer with their addresses and orders — the customer-profile view. Both
/// child collections are one-to-many relations loaded in bulk (no N+1).
class CustomerProfile {
  const CustomerProfile({
    required this.customer,
    required this.addresses,
    required this.orders,
  });

  final Customer customer;
  final List<Address> addresses;
  final List<OrderSummary> orders;

  double get totalSpent =>
      orders.fold(0, (sum, order) => sum + order.total);
}
