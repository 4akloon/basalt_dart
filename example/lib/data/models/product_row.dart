import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/category_row.dart';

part 'product_row.g.dart';

/// **Read** model for `products` (write model: `ProductWrite`). `isActive` is a
/// raw 0/1 int (SQLite has no boolean); the mapper converts it. Belongs to one
/// [category].
@Queryable(Products.table)
class ProductRow {
  const ProductRow({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.isActive,
    this.category,
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
}
