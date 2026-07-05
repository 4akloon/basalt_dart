/// A single line of a not-yet-persisted order (the checkout payload).
class NewOrderLine {
  const NewOrderLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final int productId;
  final int quantity;
  final double unitPrice;
}

/// The input to `OrderRepository.placeOrder` — everything needed to create an
/// order and its line items in one transaction.
class NewOrder {
  const NewOrder({
    required this.customerId,
    required this.lines,
    this.shippingAddressId,
  });

  final int customerId;
  final int? shippingAddressId;
  final List<NewOrderLine> lines;
}
