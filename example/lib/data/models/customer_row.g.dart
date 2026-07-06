// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [CustomerRow] — the object *is* the
/// query (`db.fetch(CustomerRowQuery())`).
final class CustomerRowQuery extends MappedQuery<CustomerRow> {
  CustomerRowQuery() : super(_build(), fromRow);

  static Query<Customers> _build() => from(Customers.table).select([
        Customers.id,
        Customers.name,
        Customers.email,
        Customers.loyaltyTier,
        Customers.createdAt
      ]);

  /// Reads a [CustomerRow] from [r] at [src] (alias-aware, composable).
  static CustomerRow fromRow(
    RowReader r, [
    QuerySource<Customers> src = Customers.table,
  ]) =>
      CustomerRow(
        id: r.get(src.col(Customers.id)),
        name: r.get(src.col(Customers.name)),
        email: r.get(src.col(Customers.email)),
        loyaltyTier: r.get(src.col(Customers.loyaltyTier)),
        createdAt: r.get(src.col(Customers.createdAt)),
      );

  /// Reusable row mapper: `from(t).mapWith(CustomerRowQuery.mapper)`.
  static const mapper = RowMapper<CustomerRow>(fromRow);
}

// **************************************************************************
// InsertableGenerator
// **************************************************************************

extension CustomerRowInsert on CustomerRow {
  InsertStatement<Customers> toInsert() => insertInto(Customers.table)
      .value(Customers.name.set(name))
      .value(Customers.email.set(email))
      .value(Customers.loyaltyTier.set(loyaltyTier))
      .value(Customers.createdAt.set(createdAt));
}

// **************************************************************************
// AsChangesetGenerator
// **************************************************************************

extension CustomerRowChangeset on CustomerRow {
  UpdateStatement<Customers> toUpdate() => update(Customers.table)
      .value(Customers.name.set(name))
      .value(Customers.email.set(email))
      .value(Customers.loyaltyTier.set(loyaltyTier))
      .value(Customers.createdAt.set(createdAt));
}
