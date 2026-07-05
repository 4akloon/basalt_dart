// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_profile_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

CustomerProfileRow $CustomerProfileRowFromRow(
  RowReader r, [
  QuerySource<Customers> src = Customers.table,
]) =>
    CustomerProfileRow(
      id: r.get(src.col(Customers.id)),
      name: r.get(src.col(Customers.name)),
      email: r.get(src.col(Customers.email)),
      loyaltyTier: r.get(src.col(Customers.loyaltyTier)),
      createdAt: r.get(src.col(Customers.createdAt)),
    );

const customerProfileRowMapper =
    RowMapper<CustomerProfileRow>($CustomerProfileRowFromRow);

MappedQuery<CustomerProfileRow> get customerProfileRowQuery =>
    from(Customers.table).select([
      Customers.id,
      Customers.name,
      Customers.email,
      Customers.loyaltyTier,
      Customers.createdAt
    ]).map($CustomerProfileRowFromRow);

/// Fetch the CustomerProfileRow with the given primary key.
MappedQuery<CustomerProfileRow> findCustomerProfileRow(int id) =>
    customerProfileRowQuery.findBy(Customers.id, id);

Future<List<CustomerProfileRow>> loadCustomerProfileRow(
  Connection db, {
  MappedQuery<CustomerProfileRow>? query,
}) async {
  final base = await (query ?? customerProfileRowQuery).load(db);
  if (base.isEmpty) return base;
  final keys = [for (final row in base) row.id];
  final addressesByParent = {
    for (final k in keys) k: <AddressRow>[],
  };
  final addressesRows =
      await addressRowQuery.where(Addresses.customerId.isIn(keys)).load(db);
  for (final row in addressesRows) {
    (addressesByParent[row.customerId] ??= []).add(row);
  }
  final ordersByParent = {
    for (final k in keys) k: <OrderRow>[],
  };
  final ordersRows = await loadOrderRow(
    db,
    query: orderRowQuery.where(Orders.customerId.isIn(keys)),
  );
  for (final row in ordersRows) {
    (ordersByParent[row.customerId] ??= []).add(row);
  }
  return [
    for (final row in base)
      CustomerProfileRow(
        id: row.id,
        name: row.name,
        email: row.email,
        loyaltyTier: row.loyaltyTier,
        createdAt: row.createdAt,
        addresses: addressesByParent[row.id] ?? const [],
        orders: ordersByParent[row.id] ?? const [],
      ),
  ];
}

Future<CustomerProfileRow?> findCustomerProfileRowById(
    Connection db, int id) async {
  final rows = await loadCustomerProfileRow(db,
      query: customerProfileRowQuery.findBy(Customers.id, id));
  return rows.isEmpty ? null : rows.single;
}
