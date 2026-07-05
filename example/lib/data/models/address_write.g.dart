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
