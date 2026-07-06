// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

/// Generated read-side query for [CategoryRow] — the object *is* the
/// query (`db.fetch(CategoryRowQuery())`).
final class CategoryRowQuery extends MappedQuery<CategoryRow> {
  CategoryRowQuery() : super(_build(), _decode);

  static Query<Object?> _build() {
    final parent = Categories.table.aliased('parent');
    return from(Categories.table).leftJoin(
      parent,
      on: Categories.parentId.eqColumn(parent.col(Categories.id)),
    );
  }

  static CategoryRow _decode(RowReader r) =>
      fromRow(r, Categories.table, '', 1);

  /// Reads a [CategoryRow] from [r] at [src] (alias-aware, composable).
  static CategoryRow fromRow(
    RowReader r, [
    QuerySource<Categories> src = Categories.table,
    String prefix = '',
    int budget = 0,
  ]) =>
      CategoryRow(
        id: r.get(src.col(Categories.id)),
        name: r.get(src.col(Categories.name)),
        parentId: r.get(src.col(Categories.parentId)),
        parent: (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) <= 0
            ? null
            : r.get(src.col(Categories.parentId)) == null
                ? null
                : CategoryRowQuery.fromRow(
                    r,
                    Categories.table.aliased('${prefix}parent'),
                    '${prefix}parent_',
                    (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) - 1,
                  ),
      );

  /// Reusable row mapper: `from(t).mapWith(CategoryRowQuery.mapper)`.
  static const mapper = RowMapper<CategoryRow>(fromRow);
}
