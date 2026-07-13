// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_review_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [ProductReviewRow] — the object *is* the
/// query (`db.fetch(ProductReviewRowQuery())`).
final class ProductReviewRowQuery extends MappedQuery<ProductReviewRow> {
  ProductReviewRowQuery() : super(_build(), _decode);

  static Query<Object?> _build() {
    final customer = Customers.table.aliased('customer');
    return from(Reviews.table).innerJoin(
      customer,
      on: Reviews.customerId.eqColumn(customer.col(Customers.id)),
    );
  }

  static ProductReviewRow _decode(RowReader r) =>
      fromRow(r, Reviews.table, '', 1);

  /// Reads a [ProductReviewRow] from [r] at [src] (alias-aware, composable).
  static ProductReviewRow fromRow(
    RowReader r, [
    QuerySource<Reviews> src = Reviews.table,
    String prefix = '',
    int budget = 0,
  ]) =>
      ProductReviewRow(
        id: r.get(src.col(Reviews.id)),
        productId: r.get(src.col(Reviews.productId)),
        customerId: r.get(src.col(Reviews.customerId)),
        rating: r.get(src.col(Reviews.rating)),
        createdAt: r.get(src.col(Reviews.createdAt)),
        comment: r.get(src.col(Reviews.comment)),
        customer: (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
            ? null
            : CustomerRowQuery.fromRow(
                r, Customers.table.aliased('${prefix}customer')),
      );

  /// Reusable row mapper: `from(t).mapWith(ProductReviewRowQuery.mapper)`.
  static const mapper = RowMapper<ProductReviewRow>(fromRow);
}
