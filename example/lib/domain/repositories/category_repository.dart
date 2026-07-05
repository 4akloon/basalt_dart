import 'package:basalt_example/domain/entities/category.dart';
import 'package:basalt_example/domain/entities/views/category_node.dart';

/// Read access to the category hierarchy.
abstract interface class CategoryRepository {
  /// Every category, flat.
  Future<List<Category>> all();

  /// The category forest (roots with nested children) plus a per-category
  /// product count.
  Future<List<CategoryNode>> tree();
}
