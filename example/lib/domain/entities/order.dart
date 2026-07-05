import 'package:basalt_example/domain/entities/address.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/order_status.dart';

/// A customer order header. [customer] and [shippingAddress] are resolved
/// belongs-to relations; line items live in `OrderSummary`.
class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.status,
    required this.placedAt,
    this.shippingAddressId,
    this.customer,
    this.shippingAddress,
  });

  final int id;
  final int customerId;
  final OrderStatus status;
  final DateTime placedAt;
  final int? shippingAddressId;
  final Customer? customer;
  final Address? shippingAddress;
}
