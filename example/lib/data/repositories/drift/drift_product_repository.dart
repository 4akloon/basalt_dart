import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/data/repositories/drift/drift_lookups.dart';
import 'package:basalt_example/data/repositories/drift/drift_mappers.dart';
import 'package:basalt_example/domain/entities/product.dart';
import 'package:basalt_example/domain/entities/views/product_with_stats.dart';
import 'package:basalt_example/domain/repositories/product_repository.dart';
import 'package:drift/drift.dart';

/// Drift-backed [ProductRepository], built on drift's generated manager API.
class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db);

  final ShopDriftDatabase _db;

  @override
  Future<List<Product>> list({String? search, int? categoryId}) async {
    final products = await _db.managers.products.filter((f) {
      var predicate = f.isActive.equals(1);
      final term = search?.trim();
      if (term != null && term.isNotEmpty) {
        predicate = predicate & f.name.contains(term);
      }
      if (categoryId != null) {
        predicate = predicate & f.categoryId.id.equals(categoryId);
      }
      return predicate;
    }).orderBy((o) => o.name.asc()).get();

    final categories = await loadCategoryIndex(_db);
    return [
      for (final p in products)
        productToDomain(p, category: categories[p.categoryId]),
    ];
  }

  @override
  Future<ProductWithStats?> detail(int id) async {
    final product =
        await _db.managers.products.filter((f) => f.id.equals(id)).getSingleOrNull();
    if (product == null) return null;

    final categories = await loadCategoryIndex(_db);

    // Reviews with their author, newest first — one join instead of fetching
    // every customer to resolve authors in memory.
    final reviewRows = await (_db.select(_db.reviews).join([
      innerJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.reviews.customerId),
      ),
    ])
          ..where(_db.reviews.productId.equals(id))
          ..orderBy([OrderingTerm.desc(_db.reviews.createdAt)]))
        .get();
    final reviews = [
      for (final r in reviewRows)
        reviewToDomain(
          r.readTable(_db.reviews),
          author: customerToDomain(r.readTable(_db.customers)),
        ),
    ];

    final count = reviews.length;
    final average = count == 0
        ? null
        : reviews.fold<double>(0, (sum, r) => sum + r.rating) / count;

    return ProductWithStats(
      product: productToDomain(product, category: categories[product.categoryId]),
      averageRating: average,
      reviewCount: count,
      reviews: reviews,
    );
  }
}
