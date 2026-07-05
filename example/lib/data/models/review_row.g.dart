// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

ReviewRow $ReviewRowFromRow(
  RowReader r, [
  QuerySource<Reviews> src = Reviews.table,
  String prefix = '',
  int budget = 0,
]) =>
    ReviewRow(
      id: r.get(src.col(Reviews.id)),
      productId: r.get(src.col(Reviews.productId)),
      customerId: r.get(src.col(Reviews.customerId)),
      rating: r.get(src.col(Reviews.rating)),
      createdAt: r.get(src.col(Reviews.createdAt)),
      comment: r.get(src.col(Reviews.comment)),
      product: (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
          ? null
          : $ProductRowFromRow(
              r,
              Products.table.aliased('${prefix}product'),
              '${prefix}product_',
              (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) - 1,
            ),
      customer: (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
          ? null
          : $CustomerRowFromRow(
              r, Customers.table.aliased('${prefix}customer')),
    );

const reviewRowMapper = RowMapper<ReviewRow>($ReviewRowFromRow);

MappedQuery<ReviewRow> get reviewRowQuery {
  final product = Products.table.aliased('product');
  final customer = Customers.table.aliased('customer');
  return from(Reviews.table)
      .innerJoin(
        product,
        on: Reviews.productId.eqColumn(product.col(Products.id)),
      )
      .innerJoin(
        customer,
        on: Reviews.customerId.eqColumn(customer.col(Customers.id)),
      )
      .map((r) => $ReviewRowFromRow(r, Reviews.table, '', 1));
}
