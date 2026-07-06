// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_customer_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [TopCustomerRow] — the object *is* the
/// query (`db.fetch(TopCustomerRowQuery())`).
final class TopCustomerRowQuery extends MappedQuery<TopCustomerRow> {
  TopCustomerRowQuery() : super(_build(), _decode);

  static final _totalSpent = TopCustomerRow._totalSpent();
  static final _orderCount = TopCustomerRow._orderCount();

  static Query<Object?> _build() => from(Customers.table)
          .innerJoin(Orders.table, onFk: Orders.customerId)
          .innerJoin(OrderItems.table, onFk: OrderItems.orderId)
          .select([
        Customers.id,
        Customers.name,
        Customers.email,
        Customers.loyaltyTier,
        Customers.createdAt,
        _totalSpent,
        _orderCount
      ]).groupBy([
        Customers.id,
        Customers.name,
        Customers.email,
        Customers.loyaltyTier,
        Customers.createdAt
      ]).orderBy(_totalSpent.desc());

  static TopCustomerRow _decode(RowReader r) => TopCustomerRow(
        id: r.get(Customers.id),
        name: r.get(Customers.name),
        email: r.get(Customers.email),
        loyaltyTier: r.get(Customers.loyaltyTier),
        createdAt: r.get(Customers.createdAt),
        totalSpent: r.get(_totalSpent) ?? 0,
        orderCount: r.get(_orderCount) ?? 0,
      );
}
