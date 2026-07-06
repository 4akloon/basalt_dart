// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_detail_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [ProductDetailRow] — the object *is* the
/// query (`db.fetch(ProductDetailRowQuery())`).
final class ProductDetailRowQuery extends FoldMappedQuery<ProductDetailRow> {
  ProductDetailRowQuery() : super(_build(), fold, rootPkColumn: Products.id);

  static Query<Object?> _build() {
    final category = Categories.table.aliased('category');
    final reviews = Reviews.table.aliased('reviews');
    final reviewsProduct = Products.table.aliased('reviews_product');
    final reviewsCustomer = Customers.table.aliased('reviews_customer');
    return from(Products.table)
        .innerJoin(
          category,
          on: Products.categoryId.eqColumn(category.col(Categories.id)),
        )
        .leftJoin(
          reviews,
          on: reviews.col(Reviews.productId).eqColumn(Products.id),
        )
        .leftJoin(
          reviewsProduct,
          on: reviews
              .col(Reviews.productId)
              .eqColumn(reviewsProduct.col(Products.id)),
        )
        .leftJoin(
          reviewsCustomer,
          on: reviews
              .col(Reviews.customerId)
              .eqColumn(reviewsCustomer.col(Customers.id)),
        );
  }

  /// Reads a [ProductDetailRow] from [r] at [src] (alias-aware, composable).
  static ProductDetailRow fromRow(
    RowReader r, [
    QuerySource<Products> src = Products.table,
    String prefix = '',
    int budget = 0,
  ]) =>
      ProductDetailRow(
        id: r.get(src.col(Products.id)),
        name: r.get(src.col(Products.name)),
        description: r.get(src.col(Products.description)),
        price: r.get(src.col(Products.price)),
        stock: r.get(src.col(Products.stock)),
        categoryId: r.get(src.col(Products.categoryId)),
        isActive: r.get(src.col(Products.isActive)),
        category: (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
            ? null
            : CategoryRowQuery.fromRow(
                r,
                Categories.table.aliased('${prefix}category'),
                '${prefix}category_',
                (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) - 1,
              ),
      );

  /// Reusable row mapper: `from(t).mapWith(ProductDetailRowQuery.mapper)`.
  static const mapper = RowMapper<ProductDetailRow>(fromRow);

  /// Folds flat JOIN rows into deduplicated parents.
  static List<ProductDetailRow> fold(
    List<RowReader> rows,
  ) {
    final parents = <int, _ProductDetailRowFoldAcc>{};
    for (final r in rows) {
      final pk = r.get(Products.id);
      final acc = parents.putIfAbsent(
          pk,
          () => _ProductDetailRowFoldAcc(
                fromRow(r, Products.table, '', 1),
              ));
      if (r.isPresent(Reviews.table.aliased('reviews').col(Reviews.id))) {
        final childPk = r.get(Reviews.table.aliased('reviews').col(Reviews.id));
        acc.reviews.putIfAbsent(
            childPk,
            () => ReviewRowQuery.fromRow(
                  r,
                  Reviews.table.aliased('reviews'),
                  'reviews_',
                  1,
                ));
      }
    }
    return [for (final a in parents.values) a.build()];
  }
}

final class _ProductDetailRowFoldAcc {
  _ProductDetailRowFoldAcc(this.base);
  final ProductDetailRow base;
  final reviews = <int, ReviewRow>{};

  ProductDetailRow build() => ProductDetailRow(
        id: base.id,
        name: base.name,
        description: base.description,
        price: base.price,
        stock: base.stock,
        categoryId: base.categoryId,
        isActive: base.isActive,
        category: base.category,
        reviews: [for (final c in reviews.values) c],
      );
}
