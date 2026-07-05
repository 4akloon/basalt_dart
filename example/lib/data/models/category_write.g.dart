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
