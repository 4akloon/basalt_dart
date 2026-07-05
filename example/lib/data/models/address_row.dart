import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/customer_row.dart';

part 'address_row.g.dart';

/// **Read** model for `addresses` (write model: `AddressWrite`). Belongs to one
/// [customer].
@Queryable(Addresses.table)
class AddressRow {
  const AddressRow({
    required this.id,
    required this.customerId,
    required this.label,
    required this.city,
    required this.street,
    this.customer,
  });

  final int id;
  final int customerId;
  final String label;
  final String city;
  final String street;

  @Relation(Addresses.customerId)
  final CustomerRow? customer;
}
