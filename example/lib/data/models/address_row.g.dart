// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

AddressRow $AddressRowFromRow(
  RowReader r, [
  QuerySource<Addresses> src = Addresses.table,
  String prefix = '',
  int budget = 0,
]) =>
    AddressRow(
      id: r.get(src.col(Addresses.id)),
      customerId: r.get(src.col(Addresses.customerId)),
      label: r.get(src.col(Addresses.label)),
      city: r.get(src.col(Addresses.city)),
      street: r.get(src.col(Addresses.street)),
      customer: (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
          ? null
          : $CustomerRowFromRow(
              r, Customers.table.aliased('${prefix}customer')),
    );

const addressRowMapper = RowMapper<AddressRow>($AddressRowFromRow);

MappedQuery<AddressRow> get addressRowQuery {
  final customer = Customers.table.aliased('customer');
  return from(Addresses.table)
      .innerJoin(
        customer,
        on: Addresses.customerId.eqColumn(customer.col(Customers.id)),
      )
      .map((r) => $AddressRowFromRow(r, Addresses.table, '', 1));
}

/// Fetch the AddressRow with the given primary key.
MappedQuery<AddressRow> findAddressRow(int id) =>
    addressRowQuery.findBy(Addresses.id, id);
