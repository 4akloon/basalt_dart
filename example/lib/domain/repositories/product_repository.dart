import 'package:basalt_example/domain/entities/product.dart';
import 'package:basalt_example/domain/entities/views/product_with_stats.dart';

/// Read access to the product catalogue.
abstract interface class ProductRepository {
  /// Active products, optionally filtered by a name [search] and/or a
  /// [categoryId]. Each product carries its resolved category.
  Future<List<Product>> list({String? search, int? categoryId});

  /// A single product with its aggregate rating and individual reviews, or null
  /// if it does not exist.
  Future<ProductWithStats?> detail(int id);
}
