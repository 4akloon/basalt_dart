// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [ProductRow] — the object *is* the
/// query (`db.fetch(ProductRowQuery())`).
final class ProductRowQuery extends MappedQuery<ProductRow> {
  ProductRowQuery() : super(_build(), _decode);

  static Query<Object?> _build() {
    final category = Categories.table.aliased('category');
    return from(Products.table).innerJoin(
      category,
      on: Products.categoryId.eqColumn(category.col(Categories.id)),
    );
  }

  static ProductRow _decode(RowReader r) => fromRow(r, Products.table, '', 1);

  /// Reads a [ProductRow] from [r] at [src] (alias-aware, composable).
  static ProductRow fromRow(
    RowReader r, [
    QuerySource<Products> src = Products.table,
    String prefix = '',
    int budget = 0,
  ]) =>
      ProductRow(
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

  /// Reusable row mapper: `from(t).mapWith(ProductRowQuery.mapper)`.
  static const mapper = RowMapper<ProductRow>(fromRow);
}
