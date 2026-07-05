import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/category_row.dart';
import 'package:basalt_example/data/models/review_row.dart';

part 'product_detail_row.g.dart';

/// Product detail view: category + all reviews (each with author) in one fold query.
@Queryable(Products.table)
class ProductDetailRow {
  const ProductDetailRow({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.isActive,
    this.category,
    this.reviews = const [],
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final int isActive;

  @Relation(Products.categoryId)
  final CategoryRow? category;

  @HasMany(Reviews.productId)
  final List<ReviewRow> reviews;
}
