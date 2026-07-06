import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'category_row.g.dart';

/// **Read** model for `categories` (paired with the write model
/// `CategoryWrite`). Keeping reads and writes in separate classes lets the read
/// shape carry relations while the write shape stays a flat column list.
///
/// The `@Relation` on [parent] is a self-referential belongs-to: the generated
/// `CategoryRowQuery` left-joins the table to itself on `parent_id`, so a row's
/// immediate [parent] is filled in (its grandparent is left null — depth 1).
@Queryable(Categories.table)
class CategoryRow {
  const CategoryRow({
    required this.id,
    required this.name,
    this.parentId,
    this.parent,
  });

  final int id;
  final String name;

  /// Raw foreign key (null for a top-level category).
  final int? parentId;

  /// Read-side relation, filled by the self-join. Not a column.
  @Relation(Categories.parentId)
  final CategoryRow? parent;
}
