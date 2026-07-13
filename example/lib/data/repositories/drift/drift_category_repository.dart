import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/data/repositories/drift/drift_mappers.dart';
import 'package:basalt_example/domain/entities/category.dart';
import 'package:basalt_example/domain/entities/views/category_node.dart';
import 'package:basalt_example/domain/repositories/category_repository.dart';

/// Drift-backed [CategoryRepository], using drift's generated manager API for
/// the flat read and the `queries.drift` aggregate for the per-category counts.
class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final ShopDriftDatabase _db;

  @override
  Future<List<Category>> all() async {
    final rows =
        await _db.managers.categories.orderBy((o) => o.name.asc()).get();
    // Resolve each category's immediate parent from the same list (the basalt
    // `CategoryRowQuery` does this with a self-join).
    final byId = {for (final c in rows) c.id: c};
    Category map(DriftCategory c) => categoryToDomain(
          c,
          parent: switch (c.parentId) {
            final id? => switch (byId[id]) {
                final parent? => categoryToDomain(parent),
                null => null,
              },
            null => null,
          },
        );
    return [for (final c in rows) map(c)];
  }

  @override
  Future<List<CategoryNode>> tree() async {
    final categories = await all();

    // Per-category product count: a GROUP BY defined in queries.drift.
    final counts = <int, int>{
      for (final r in await _db.productCountsByCategory().get()) r.categoryId: r.n,
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
