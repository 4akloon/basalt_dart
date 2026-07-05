// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_write.dart';

// **************************************************************************
// InsertableGenerator
// **************************************************************************

extension ReviewWriteInsert on ReviewWrite {
  InsertStatement<Reviews> toInsert() => insertInto(Reviews.table)
      .value(Reviews.productId.set(productId))
      .value(Reviews.customerId.set(customerId))
      .value(Reviews.rating.set(rating))
      .value(Reviews.createdAt.set(createdAt))
      .value(Reviews.comment.set(comment));
}
