import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'review_write.g.dart';

/// **Write** model for `reviews`.
@Insertable(Reviews.table)
class ReviewWrite {
  const ReviewWrite({
    required this.productId,
    required this.customerId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final int productId;
  final int customerId;
  final int rating;
  final int createdAt;
  final String? comment;
}
