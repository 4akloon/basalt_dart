import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/product_detail_mapper.dart';
import 'package:basalt_example/data/mappers/product_mapper.dart';
import 'package:basalt_example/data/models/product_detail_row.dart';
import 'package:basalt_example/data/models/product_row.dart';
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
    final row = await productDetailRowQuery
        .findBy(Products.id, id)
        .order(Reviews.createdAt.desc())
        .optional(_db);
    return row?.toDomain();
  }
}
