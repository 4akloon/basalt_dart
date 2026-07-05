import 'package:basalt_example/data/mappers/category_mapper.dart';
import 'package:basalt_example/data/models/product_row.dart';
import 'package:basalt_example/domain/entities/product.dart';

/// Converts a [ProductRow] into a domain [Product], turning the raw 0/1
/// `isActive` into a `bool` and mapping the loaded category.
extension ProductRowMapper on ProductRow {
  Product toDomain() => Product(
        id: id,
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: categoryId,
        isActive: isActive == 1,
        category: category?.toDomain(),
      );
}
