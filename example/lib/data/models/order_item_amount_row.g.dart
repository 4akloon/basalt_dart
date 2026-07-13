// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_amount_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [OrderItemAmountRow] — the object *is* the
/// query (`db.fetch(OrderItemAmountRowQuery())`).
final class OrderItemAmountRowQuery extends MappedQuery<OrderItemAmountRow> {
  OrderItemAmountRowQuery() : super(_build(), fromRow);

  static Query<OrderItems> _build() => from(OrderItems.table).select([
        OrderItems.id,
        OrderItems.orderId,
        OrderItems.productId,
        OrderItems.quantity,
        OrderItems.unitPrice
      ]);

  /// Reads a [OrderItemAmountRow] from [r] at [src] (alias-aware, composable).
  static OrderItemAmountRow fromRow(
    RowReader r, [
    QuerySource<OrderItems> src = OrderItems.table,
  ]) =>
      OrderItemAmountRow(
        id: r.get(src.col(OrderItems.id)),
        orderId: r.get(src.col(OrderItems.orderId)),
        productId: r.get(src.col(OrderItems.productId)),
        quantity: r.get(src.col(OrderItems.quantity)),
        unitPrice: r.get(src.col(OrderItems.unitPrice)),
      );

  /// Reusable row mapper: `from(t).mapWith(OrderItemAmountRowQuery.mapper)`.
  static const mapper = RowMapper<OrderItemAmountRow>(fromRow);
}
