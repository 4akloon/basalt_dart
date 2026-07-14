import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/data/repositories/drift/drift_mappers.dart';
import 'package:basalt_example/domain/entities/category.dart';

/// Loads every category keyed by id, as domain [Category]s.
///
/// Products carry their (single) category; there are only a handful of
/// categories, so the product reads fetch this once and resolve in memory
/// instead of joining — the same immediate-category-only shape the basalt
/// `ProductRowQuery` produces (its category's own parent is left unloaded).
Future<Map<int, Category>> loadCategoryIndex(ShopDriftDatabase db) async {
  final rows = await db.managers.categories.get();
  return {for (final c in rows) c.id: categoryToDomain(c)};
}
