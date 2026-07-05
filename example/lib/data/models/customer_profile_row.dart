import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/address_row.dart';
import 'package:basalt_example/data/models/order_item_row.dart';
import 'package:basalt_example/data/models/order_row.dart';

part 'customer_profile_row.g.dart';

/// Customer with one-to-many children loaded via a single JOIN query.
@Queryable(Customers.table)
class CustomerProfileRow {
  const CustomerProfileRow({
    required this.id,
    required this.name,
    required this.email,
    required this.loyaltyTier,
    required this.createdAt,
    this.addresses = const [],
    this.orders = const [],
  });

  final int id;
  final String name;
  final String email;
  final String loyaltyTier;
  final int createdAt;

  @HasMany(Addresses.customerId)
  final List<AddressRow> addresses;

  @HasMany(Orders.customerId)
  final List<OrderRow> orders;
}
