import 'package:basalt_example/data/mappers/customer_mapper.dart';
import 'package:basalt_example/data/models/product_review_row.dart';
import 'package:basalt_example/domain/entities/review.dart';

/// Converts a [ProductReviewRow] into a domain [Review], mapping the author
/// ([ProductReviewRow.customer]). The review's product is left null — the
/// product-detail view already holds it.
extension ProductReviewRowMapper on ProductReviewRow {
  Review toDomain() => Review(
        id: id,
        productId: productId,
        customerId: customerId,
        rating: rating,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        comment: comment,
        customer: customer?.toDomain(),
      );
}
