// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_list_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [CategoryListRow] — the object *is* the
/// query (`db.fetch(CategoryListRowQuery())`).
final class CategoryListRowQuery extends MappedQuery<CategoryListRow> {
  CategoryListRowQuery() : super(_build(), fromRow);

  static Query<Categories> _build() => from(Categories.table)
      .select([Categories.id, Categories.name, Categories.parentId]);

  /// Reads a [CategoryListRow] from [r] at [src] (alias-aware, composable).
  static CategoryListRow fromRow(
    RowReader r, [
    QuerySource<Categories> src = Categories.table,
  ]) =>
      CategoryListRow(
        id: r.get(src.col(Categories.id)),
        name: r.get(src.col(Categories.name)),
        parentId: r.get(src.col(Categories.parentId)),
      );

  /// Reusable row mapper: `from(t).mapWith(CategoryListRowQuery.mapper)`.
  static const mapper = RowMapper<CategoryListRow>(fromRow);
}
