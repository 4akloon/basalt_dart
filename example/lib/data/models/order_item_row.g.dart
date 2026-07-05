// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

OrderItemRow $OrderItemRowFromRow(
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
          : $ProductRowFromRow(
              r,
              Products.table.aliased('${prefix}product'),
              '${prefix}product_',
              (prefix.isEmpty ? (budget > 2 ? 2 : budget) : budget) - 1,
            ),
    );

const orderItemRowMapper = RowMapper<OrderItemRow>($OrderItemRowFromRow);

MappedQuery<OrderItemRow> get orderItemRowQuery {
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
      )
      .map((r) => $OrderItemRowFromRow(r, OrderItems.table, '', 2));
}

/// Fetch the OrderItemRow with the given primary key.
MappedQuery<OrderItemRow> findOrderItemRow(int id) =>
    orderItemRowQuery.findBy(OrderItems.id, id);
