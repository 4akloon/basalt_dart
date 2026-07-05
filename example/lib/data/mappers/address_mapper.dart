import 'package:basalt_example/data/models/address_row.dart';
import 'package:basalt_example/domain/entities/address.dart';

/// Converts an [AddressRow] into a domain [Address].
extension AddressRowMapper on AddressRow {
  Address toDomain() => Address(
        id: id,
        customerId: customerId,
        label: label,
        city: city,
        street: street,
      );
}
