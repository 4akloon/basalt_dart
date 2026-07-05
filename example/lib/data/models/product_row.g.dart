// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

ProductRow $ProductRowFromRow(
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
          : $CategoryRowFromRow(
              r,
              Categories.table.aliased('${prefix}category'),
              '${prefix}category_',
              (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) - 1,
            ),
    );

const productRowMapper = RowMapper<ProductRow>($ProductRowFromRow);

MappedQuery<ProductRow> get productRowQuery {
  final category = Categories.table.aliased('category');
  return from(Products.table)
      .innerJoin(
        category,
        on: Products.categoryId.eqColumn(category.col(Categories.id)),
      )
      .map((r) => $ProductRowFromRow(r, Products.table, '', 1));
}
