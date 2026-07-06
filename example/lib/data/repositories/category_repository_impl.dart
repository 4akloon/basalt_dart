import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/category_mapper.dart';
import 'package:basalt_example/data/models/category_row.dart';
import 'package:basalt_example/domain/entities/category.dart';
import 'package:basalt_example/domain/entities/views/category_node.dart';
import 'package:basalt_example/domain/repositories/category_repository.dart';

/// SQLite-backed [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);

  final Connection _db;

  @override
  Future<List<Category>> all() async {
    final rows = await CategoryRowQuery().orderBy(Categories.name.asc()).load(_db);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<List<CategoryNode>> tree() async {
    final categories = await all();

    // Per-category product count: a typed `GROUP BY` aggregate.
    final total = countAll();
    final counts = <int, int>{
      for (final row in await _db.fetch(
        from(Products.table)
            .select([Products.categoryId, total])
            .groupBy([Products.categoryId])
            .map((r) => (categoryId: r.get(Products.categoryId), n: r.get(total))),
      ))
        row.categoryId: row.n,
    };

    // Assemble the forest in memory from the flat parent_id links.
    final childrenOf = <int?, List<Category>>{};
    for (final category in categories) {
      (childrenOf[category.parentId] ??= []).add(category);
    }

    CategoryNode build(Category category) => CategoryNode(
          category: category,
          productCount: counts[category.id] ?? 0,
          children: [
            for (final child in childrenOf[category.id] ?? const [])
              build(child),
          ],
        );

    return [for (final root in childrenOf[null] ?? const []) build(root)];
  }
}
