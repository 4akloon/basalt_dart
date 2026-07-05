// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_row.dart';

// **************************************************************************
// QueryableGenerator
// **************************************************************************

CategoryRow $CategoryRowFromRow(
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
              : $CategoryRowFromRow(
                  r,
                  Categories.table.aliased('${prefix}parent'),
                  '${prefix}parent_',
                  (prefix.isEmpty ? (budget > 1 ? 1 : budget) : budget) - 1,
                ),
    );

const categoryRowMapper = RowMapper<CategoryRow>($CategoryRowFromRow);

MappedQuery<CategoryRow> get categoryRowQuery {
  final parent = Categories.table.aliased('parent');
  return from(Categories.table)
      .leftJoin(
        parent,
        on: Categories.parentId.eqColumn(parent.col(Categories.id)),
      )
      .map((r) => $CategoryRowFromRow(r, Categories.table, '', 1));
}
