import 'package:basalt_example/data/mappers/customer_mapper.dart';
import 'package:basalt_example/data/mappers/product_mapper.dart';
import 'package:basalt_example/data/models/review_row.dart';
import 'package:basalt_example/domain/entities/review.dart';

/// Converts a [ReviewRow] into a domain [Review], mapping the nested product and
/// author.
extension ReviewRowMapper on ReviewRow {
  Review toDomain() => Review(
        id: id,
        productId: productId,
        customerId: customerId,
        rating: rating,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        comment: comment,
        product: product?.toDomain(),
        customer: customer?.toDomain(),
      );
}
