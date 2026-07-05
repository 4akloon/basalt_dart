import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'category_write.g.dart';

/// **Write** model for `categories`. A flat, relation-free column list with no
/// `id` — SQLite autoincrements the primary key. Build one and call
/// `toInsert()`.
@Insertable(Categories.table)
class CategoryWrite {
  const CategoryWrite({required this.name, this.parentId});

  final String name;
  final int? parentId;
}
