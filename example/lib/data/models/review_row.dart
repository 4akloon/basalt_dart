import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/customer_row.dart';
import 'package:basalt_example/data/models/product_row.dart';

part 'review_row.g.dart';

/// **Read** model for `reviews` (write model: `ReviewWrite`). Belongs to both a
/// [product] and a [customer], so `ReviewRowQuery` joins two parents at once.
@Queryable(Reviews.table)
class ReviewRow {
  const ReviewRow({
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
  final int createdAt;
  final String? comment;

  @Relation(Reviews.productId)
  final ProductRow? product;

  @Relation(Reviews.customerId)
  final CustomerRow? customer;
}
