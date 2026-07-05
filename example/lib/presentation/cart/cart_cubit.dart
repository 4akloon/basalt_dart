import 'package:basalt_example/domain/entities/new_order.dart';
import 'package:basalt_example/domain/entities/product.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';
import 'package:basalt_example/presentation/cart/cart_item.dart';
import 'package:basalt_example/presentation/cart/cart_state.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the in-memory cart and turns it into a persisted order at checkout.
class CartCubit extends Cubit<CartState> {
  CartCubit(this._orders) : super(const CartState());

  final OrderRepository _orders;

  void add(Product product) {
    final items = [...state.items];
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(CartItem(product: product, quantity: 1));
    }
    emit(state.copyWith(items: items, checkout: LoadStatus.initial));
  }

  void setQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final items = [
      for (final item in state.items)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
    emit(state.copyWith(items: items));
  }

  void remove(int productId) {
    emit(state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.id != productId) item,
      ],
    ));
  }

  void clear() => emit(const CartState());

  /// Persists the cart as an order for [customerId] (optionally shipped to
  /// [addressId]) in a single transaction, then empties the cart.
  Future<void> checkout({required int customerId, int? addressId}) async {
    if (state.isEmpty) return;
    emit(state.copyWith(checkout: LoadStatus.loading, error: null));
    try {
      final orderId = await _orders.placeOrder(
        NewOrder(
          customerId: customerId,
          shippingAddressId: addressId,
          lines: [
            for (final item in state.items)
              NewOrderLine(
                productId: item.product.id,
                quantity: item.quantity,
                unitPrice: item.product.price,
              ),
          ],
        ),
      );
      emit(CartState(checkout: LoadStatus.success, lastOrderId: orderId));
    } catch (e) {
      emit(state.copyWith(checkout: LoadStatus.failure, error: '$e'));
    }
  }
}
