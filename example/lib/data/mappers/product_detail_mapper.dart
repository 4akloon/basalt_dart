import 'package:basalt_example/data/mappers/product_mapper.dart';
import 'package:basalt_example/data/mappers/product_review_mapper.dart';
import 'package:basalt_example/data/models/product_detail_row.dart';
import 'package:basalt_example/data/models/product_row.dart';
import 'package:basalt_example/domain/entities/views/product_with_stats.dart';

extension ProductDetailRowMapper on ProductDetailRow {
  ProductWithStats toDomain() {
    final domainReviews = [for (final r in reviews) r.toDomain()];
    final count = domainReviews.length;
    final average = count == 0
        ? null
        : domainReviews.fold<double>(
              0,
              (sum, r) => sum + r.rating,
            ) /
            count;

    return ProductWithStats(
      product: ProductRow(
        id: id,
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: categoryId,
        isActive: isActive,
        metadata: metadata,
        category: category,
      ).toDomain(),
      averageRating: average,
      reviewCount: count,
      reviews: domainReviews,
    );
  }
}
