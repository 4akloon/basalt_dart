// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_write.dart';

// **************************************************************************
// InsertableGenerator
// **************************************************************************

extension ProductWriteInsert on ProductWrite {
  InsertStatement<Products> toInsert() => insertInto(Products.table)
      .value(Products.name.set(name))
      .value(Products.description.set(description))
      .value(Products.price.set(price))
      .value(Products.stock.set(stock))
      .value(Products.categoryId.set(categoryId))
      .value(Products.isActive.set(isActive))
      .value(Products.metadata.set(metadata));
}

extension ProductWriteBatchInsert on Iterable<ProductWrite> {
  InsertStatement<Products> toInsert() {
    final rows = [
      for (final row in this)
        [
          Products.name.set(row.name),
          Products.description.set(row.description),
          Products.price.set(row.price),
          Products.stock.set(row.stock),
          Products.categoryId.set(row.categoryId),
          Products.isActive.set(row.isActive),
          Products.metadata.set(row.metadata),
        ],
    ];
    if (rows.isEmpty) {
      throw ArgumentError('toInsert() on an empty Iterable<ProductWrite>: '
          'an INSERT needs at least one row.');
    }
    return insertInto(Products.table).values(rows);
  }
}
