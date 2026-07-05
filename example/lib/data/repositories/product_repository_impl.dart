import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/product_mapper.dart';
import 'package:basalt_example/data/mappers/review_mapper.dart';
import 'package:basalt_example/data/models/product_row.dart';
import 'package:basalt_example/data/models/review_row.dart';
import 'package:basalt_example/domain/entities/product.dart';
import 'package:basalt_example/domain/entities/views/product_with_stats.dart';
import 'package:basalt_example/domain/repositories/product_repository.dart';

/// SQLite-backed [ProductRepository].
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._db);

  final Connection _db;

  @override
  Future<List<Product>> list({String? search, int? categoryId}) async {
    // `productRowQuery` already inner-joins the category; we AND on extra
    // predicates with `filter` (repeated `where` would *replace*, not combine).
    var query = productRowQuery.filter(Products.isActive.eq(1));
    if (search != null && search.trim().isNotEmpty) {
      query = query.filter(Products.name.like('%${search.trim()}%'));
    }
    if (categoryId != null) {
      query = query.filter(Products.categoryId.eq(categoryId));
    }
    final rows = await query.orderBy(Products.name.asc()).load(_db);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<ProductWithStats?> detail(int id) async {
    final row = await findProductRow(id).optional(_db);
    if (row == null) return null;

    // Reviews (each with its author) via the generated relation query.
    final reviewRows = await reviewRowQuery
        .where(Reviews.productId.eq(id))
        .orderBy(Reviews.createdAt.desc())
        .load(_db);

    // Aggregate rating + count in one grouped-free aggregate query.
    final avgRating = Reviews.rating.avg();
    final total = countAll();
    final stats = await _db.fetch(
      from(Reviews.table)
          .select([avgRating, total])
          .where(Reviews.productId.eq(id))
          .map((r) => (avg: r.get(avgRating), count: r.get(total))),
    );
    final agg = stats.single;

    return ProductWithStats(
      product: row.toDomain(),
      averageRating: agg.avg,
      reviewCount: agg.count,
      reviews: [for (final review in reviewRows) review.toDomain()],
    );
  }
}
