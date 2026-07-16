// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_write.dart';

// **************************************************************************
// InsertableGenerator
// **************************************************************************

extension CategoryWriteInsert on CategoryWrite {
  InsertStatement<Categories> toInsert() => insertInto(Categories.table)
      .value(Categories.name.set(name))
      .value(Categories.parentId.set(parentId));
}

extension CategoryWriteBatchInsert on Iterable<CategoryWrite> {
  InsertStatement<Categories> toInsert() {
    final rows = [
      for (final row in this)
        [
          Categories.name.set(row.name),
          Categories.parentId.set(row.parentId),
        ],
    ];
    if (rows.isEmpty) {
      throw ArgumentError('toInsert() on an empty Iterable<CategoryWrite>: '
          'an INSERT needs at least one row.');
    }
    return insertInto(Categories.table).values(rows);
  }
}
