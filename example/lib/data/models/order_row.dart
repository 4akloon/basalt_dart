import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/address_row.dart';
import 'package:basalt_example/data/models/customer_row.dart';

part 'order_row.g.dart';

/// **Read** model for `orders` (write model: `OrderWrite`). Two belongs-to
/// relations: the required [customer] (inner join) and the nullable
/// [shippingAddress] (left join, since a draft order may not have an address).
@Queryable(Orders.table)
class OrderRow {
  const OrderRow({
    required this.id,
    required this.customerId,
    required this.status,
    required this.createdAt,
    this.shippingAddressId,
    this.customer,
    this.shippingAddress,
  });

  final int id;
  final int customerId;
  final String status;
  final int createdAt;
  final int? shippingAddressId;

  @Relation(Orders.customerId)
  final CustomerRow? customer;

  @Relation(Orders.shippingAddressId)
  final AddressRow? shippingAddress;
}
