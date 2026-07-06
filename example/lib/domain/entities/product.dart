import 'package:basalt_example/domain/entities/category.dart';

/// A catalogue product. `isActive` is a real `bool` (stored as 0/1) and
/// [category] is the resolved belongs-to relation (may be null if not loaded).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.isActive,
    this.metadata,
    this.category,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final bool isActive;

  /// Free-form JSON attributes (e.g. warranty, ports), or null if none.
  final Map<String, Object?>? metadata;

  final Category? category;

  bool get inStock => stock > 0;
}
