// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [ReviewRow] — the object *is* the
/// query (`db.fetch(ReviewRowQuery())`).
final class ReviewRowQuery extends MappedQuery<ReviewRow> {
  ReviewRowQuery() : super(_build(), _decode);

  static Query<Object?> _build() {
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
        );
  }

  static ReviewRow _decode(RowReader r) => fromRow(r, Reviews.table, '', 1);

  /// Reads a [ReviewRow] from [r] at [src] (alias-aware, composable).
  static ReviewRow fromRow(
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
            : ProductRowQuery.fromRow(
                r,
                Products.table.aliased('${prefix}product'),
                '${prefix}product_',
                (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) - 1,
              ),
        customer: (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
            ? null
            : CustomerRowQuery.fromRow(
                r, Customers.table.aliased('${prefix}customer')),
      );

  /// Reusable row mapper: `from(t).mapWith(ReviewRowQuery.mapper)`.
  static const mapper = RowMapper<ReviewRow>(fromRow);
}
