// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_revenue_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [CategoryRevenueRow] — the object *is* the
/// query (`db.fetch(CategoryRevenueRowQuery())`).
final class CategoryRevenueRowQuery extends MappedQuery<CategoryRevenueRow> {
  CategoryRevenueRowQuery() : super(_build(), _decode);

  static final _revenue = CategoryRevenueRow._revenue();
  static final _unitsSold = CategoryRevenueRow._unitsSold();

  static Query<Object?> _build() => from(OrderItems.table)
      .innerJoin(Products.table, onFk: OrderItems.productId)
      .innerJoin(Categories.table, onFk: Products.categoryId)
      .select([Categories.name, _revenue, _unitsSold]).groupBy(
          [Categories.name]).orderBy(_revenue.desc());

  static CategoryRevenueRow _decode(RowReader r) => CategoryRevenueRow(
        categoryName: r.get(Categories.name),
        revenue: r.get(_revenue) ?? 0,
        unitsSold: r.get(_unitsSold) ?? 0,
      );
}
