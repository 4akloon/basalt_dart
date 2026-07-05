import 'package:basalt_example/domain/entities/product.dart';
import 'package:basalt_example/domain/entities/review.dart';

/// A product enriched with aggregate review data — the product-detail view.
///
/// [averageRating] and [reviewCount] come from a single `AVG(rating)` /
/// `COUNT(*)` aggregate query; [reviews] are the individual reviews (each with
/// its author) loaded alongside.
class ProductWithStats {
  const ProductWithStats({
    required this.product,
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
  });

  final Product product;
  final double? averageRating;
  final int reviewCount;
  final List<Review> reviews;
}
