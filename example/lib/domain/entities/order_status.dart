/// Lifecycle state of an order. Stored in the database as its [name] and decoded
/// back by the mapper.
enum OrderStatus {
  pending,
  paid,
  shipped,
  delivered,
  cancelled;

  /// Human-readable label for the UI.
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.paid => 'Paid',
        OrderStatus.shipped => 'Shipped',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  /// Whether the order can still transition to another state.
  bool get isOpen => this != OrderStatus.delivered && this != OrderStatus.cancelled;
}
