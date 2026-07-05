import 'package:basalt_example/data/models/category_row.dart';
import 'package:basalt_example/domain/entities/category.dart';

/// Converts a data-layer [CategoryRow] into a domain [Category], recursing into
/// the loaded [CategoryRow.parent].
extension CategoryRowMapper on CategoryRow {
  Category toDomain() => Category(
        id: id,
        name: name,
        parentId: parentId,
        parent: parent?.toDomain(),
      );
}
