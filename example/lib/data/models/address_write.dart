import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'address_write.g.dart';

/// **Write** model for `addresses`.
@Insertable(Addresses.table)
class AddressWrite {
  const AddressWrite({
    required this.customerId,
    required this.label,
    required this.city,
    required this.street,
  });

  final int customerId;
  final String label;
  final String city;
  final String street;
}
