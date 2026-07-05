import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/product.dart';

/// A product review (1..5 stars) written by a customer. Both [product] and
/// [customer] are resolved belongs-to relations.
class Review {
  const Review({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.product,
    this.customer,
  });

  final int id;
  final int productId;
  final int customerId;
  final int rating;
  final DateTime createdAt;
  final String? comment;
  final Product? product;
  final Customer? customer;
}
