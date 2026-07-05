// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_revenue_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

MappedQuery<CategoryRevenueRow> get categoryRevenueRowQuery {
  return from(OrderItems.table)
      .innerJoin(Products.table, onFk: OrderItems.productId)
      .innerJoin(Categories.table, onFk: Products.categoryId)
      .select([
        Categories.name,
        CategoryRevenueRow._revenue(),
        CategoryRevenueRow._unitsSold()
      ])
      .groupBy([Categories.name])
      .orderBy(CategoryRevenueRow._revenue().desc())
      .map((r) => CategoryRevenueRow(
            categoryName: r.get(Categories.name),
            revenue: r.get(CategoryRevenueRow._revenue()) ?? 0,
            unitsSold: r.get(CategoryRevenueRow._unitsSold()) ?? 0,
          ));
}
