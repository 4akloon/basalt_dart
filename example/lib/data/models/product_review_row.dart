import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/customer_row.dart';

part 'product_review_row.g.dart';

/// Lean read model for a product's reviews: the review columns plus its author
/// ([customer]) only.
///
/// Unlike `ReviewRow` (which declares belongs-to relations to *both* the product
/// and the customer), this omits the `product` relation — the product-detail
/// view already has the product it is showing, so joining it back per review is
/// wasted work.
@Queryable(Reviews.table)
class ProductReviewRow {
  const ProductReviewRow({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.customer,
  });

  final int id;
  final int productId;
  final int customerId;
  final int rating;
  final int createdAt;
  final String? comment;

  @Relation(Reviews.customerId)
  final CustomerRow? customer;
}
