import 'package:basalt_example/domain/entities/product.dart';
import 'package:basalt_example/domain/entities/review.dart';

/// A product enriched with aggregate review data — the product-detail view.
///
/// [averageRating] and [reviewCount] are derived from [reviews] after a single
/// fold query loads the product, category, and each review (with author).
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
