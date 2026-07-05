// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_customer_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

MappedQuery<TopCustomerRow> get topCustomerRowQuery {
  return from(Customers.table)
      .innerJoin(Orders.table, onFk: Orders.customerId)
      .innerJoin(OrderItems.table, onFk: OrderItems.orderId)
      .select([
        Customers.id,
        Customers.name,
        Customers.email,
        Customers.loyaltyTier,
        Customers.createdAt,
        TopCustomerRow._totalSpent(),
        TopCustomerRow._orderCount()
      ])
      .groupBy([
        Customers.id,
        Customers.name,
        Customers.email,
        Customers.loyaltyTier,
        Customers.createdAt
      ])
      .orderBy(TopCustomerRow._totalSpent().desc())
      .map((r) => TopCustomerRow(
            id: r.get(Customers.id),
            name: r.get(Customers.name),
            email: r.get(Customers.email),
            loyaltyTier: r.get(Customers.loyaltyTier),
            createdAt: r.get(Customers.createdAt),
            totalSpent: r.get(TopCustomerRow._totalSpent()) ?? 0,
            orderCount: r.get(TopCustomerRow._orderCount()) ?? 0,
          ));
}
