import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'order_write.g.dart';

/// **Write** model for `orders`, carrying *both* write derives: `@Insertable`
/// (`toInsert()`, used when placing an order) and `@AsChangeset` (`toUpdate()`,
/// used to change an order's status). Both cover the same flat column set, so a
/// single write class serves them.
@Insertable(Orders.table)
@AsChangeset(Orders.table)
class OrderWrite {
  const OrderWrite({
    required this.customerId,
    required this.status,
    required this.createdAt,
    this.shippingAddressId,
  });

  final int customerId;
  final String status;
  final int createdAt;
  final int? shippingAddressId;
}
