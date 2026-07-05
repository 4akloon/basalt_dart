import 'package:basalt_example/presentation/cart/cart_item.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:equatable/equatable.dart';

/// State for the cart — the line items plus the checkout lifecycle.
class CartState extends Equatable {
  const CartState({
    this.items = const [],
    this.checkout = LoadStatus.initial,
    this.lastOrderId,
    this.error,
  });

  final List<CartItem> items;
  final LoadStatus checkout;
  final int? lastOrderId;
  final String? error;

  double get total => items.fold(0, (sum, item) => sum + item.lineTotal);
  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  static const Object _keep = Object();

  CartState copyWith({
    List<CartItem>? items,
    LoadStatus? checkout,
    Object? lastOrderId = _keep,
    Object? error = _keep,
  }) {
    return CartState(
      items: items ?? this.items,
      checkout: checkout ?? this.checkout,
      lastOrderId: identical(lastOrderId, _keep)
          ? this.lastOrderId
          : lastOrderId as int?,
      error: identical(error, _keep) ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => [items, checkout, lastOrderId, error];
}
