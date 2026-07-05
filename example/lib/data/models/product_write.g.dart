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
      .value(Products.isActive.set(isActive));
}
