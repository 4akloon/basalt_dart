import 'package:basalt_example/domain/entities/category.dart';

/// A node in the category tree — a [category], its [children], and how many
/// products sit directly in it. Built in memory from the flat category list and
/// a per-category product count.
class CategoryNode {
  const CategoryNode({
    required this.category,
    required this.productCount,
    required this.children,
  });

  final Category category;
  final int productCount;
  final List<CategoryNode> children;
}
