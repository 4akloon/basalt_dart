// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [AddressRow] — the object *is* the
/// query (`db.fetch(AddressRowQuery())`).
final class AddressRowQuery extends MappedQuery<AddressRow> {
  AddressRowQuery() : super(_build(), _decode);

  static Query<Object?> _build() {
    final customer = Customers.table.aliased('customer');
    return from(Addresses.table).innerJoin(
      customer,
      on: Addresses.customerId.eqColumn(customer.col(Customers.id)),
    );
  }

  static AddressRow _decode(RowReader r) => fromRow(r, Addresses.table, '', 1);

  /// Reads a [AddressRow] from [r] at [src] (alias-aware, composable).
  static AddressRow fromRow(
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
            : CustomerRowQuery.fromRow(
                r, Customers.table.aliased('${prefix}customer')),
      );

  /// Reusable row mapper: `from(t).mapWith(AddressRowQuery.mapper)`.
  static const mapper = RowMapper<AddressRow>(fromRow);
}
