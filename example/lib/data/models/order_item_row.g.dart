// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [OrderItemRow] — the object *is* the
/// query (`db.fetch(OrderItemRowQuery())`).
final class OrderItemRowQuery extends MappedQuery<OrderItemRow> {
  OrderItemRowQuery() : super(_build(), _decode);

  static Query<Object?> _build() {
    final product = Products.table.aliased('product');
    final productCategory = Categories.table.aliased('product_category');
    return from(OrderItems.table)
        .innerJoin(
          product,
          on: OrderItems.productId.eqColumn(product.col(Products.id)),
        )
        .innerJoin(
          productCategory,
          on: product
              .col(Products.categoryId)
              .eqColumn(productCategory.col(Categories.id)),
        );
  }

  static OrderItemRow _decode(RowReader r) =>
      fromRow(r, OrderItems.table, '', 2);

  /// Reads a [OrderItemRow] from [r] at [src] (alias-aware, composable).
  static OrderItemRow fromRow(
    RowReader r, [
    QuerySource<OrderItems> src = OrderItems.table,
    String prefix = '',
    int budget = 0,
  ]) =>
      OrderItemRow(
        id: r.get(src.col(OrderItems.id)),
        orderId: r.get(src.col(OrderItems.orderId)),
        productId: r.get(src.col(OrderItems.productId)),
        quantity: r.get(src.col(OrderItems.quantity)),
        unitPrice: r.get(src.col(OrderItems.unitPrice)),
        product: (prefix.isEmpty ? (budget > 2 ? 2 : budget) : budget) <= 0
            ? null
            : ProductRowQuery.fromRow(
                r,
                Products.table.aliased('${prefix}product'),
                '${prefix}product_',
                (prefix.isEmpty ? (budget > 2 ? 2 : budget) : budget) - 1,
              ),
      );

  /// Reusable row mapper: `from(t).mapWith(OrderItemRowQuery.mapper)`.
  static const mapper = RowMapper<OrderItemRow>(fromRow);
}
