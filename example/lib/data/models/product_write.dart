import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'product_write.g.dart';

/// **Write** model for `products`. `isActive` is the raw 0/1 int the column
/// stores.
@Insertable(Products.table)
class ProductWrite {
  const ProductWrite({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.isActive,
    this.metadata,
  });

  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final int isActive;

  /// Free-form JSON attributes, written through the custom
  /// `JsonMapSqlType` codec (`products.metadata`).
  final Map<String, Object?>? metadata;
}
