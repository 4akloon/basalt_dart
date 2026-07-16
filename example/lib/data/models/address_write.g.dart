// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_write.dart';

// **************************************************************************
// InsertableGenerator
// **************************************************************************

extension AddressWriteInsert on AddressWrite {
  InsertStatement<Addresses> toInsert() => insertInto(Addresses.table)
      .value(Addresses.customerId.set(customerId))
      .value(Addresses.label.set(label))
      .value(Addresses.city.set(city))
      .value(Addresses.street.set(street));
}

extension AddressWriteBatchInsert on Iterable<AddressWrite> {
  InsertStatement<Addresses> toInsert() {
    final rows = [
      for (final row in this)
        [
          Addresses.customerId.set(row.customerId),
          Addresses.label.set(row.label),
          Addresses.city.set(row.city),
          Addresses.street.set(row.street),
        ],
    ];
    if (rows.isEmpty) {
      throw ArgumentError('toInsert() on an empty Iterable<AddressWrite>: '
          'an INSERT needs at least one row.');
    }
    return insertInto(Addresses.table).values(rows);
  }
}
