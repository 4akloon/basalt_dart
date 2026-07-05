import 'package:basalt_example/domain/entities/product.dart';
import 'package:equatable/equatable.dart';

/// A product plus the quantity the shopper has added to the cart.
class CartItem extends Equatable {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product.id, quantity];
}
