import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';

part 'category_list_row.g.dart';

/// Lean read model for `categories` — the flat columns only, with **no**
/// `parent` relation.
///
/// `CategoryRow` declares a self-referential `@Relation(parent)`, so using it as
/// a query root left-joins the table to itself. The category list and tree only
/// need `parentId` (the tree is assembled in memory; the resolved parent object
/// is never read), so this model drops that self-join entirely.
@Queryable(Categories.table)
class CategoryListRow {
  const CategoryListRow({
    required this.id,
    required this.name,
    this.parentId,
  });

  final int id;
  final String name;
  final int? parentId;
}
