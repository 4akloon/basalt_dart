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

extension ReviewWriteBatchInsert on Iterable<ReviewWrite> {
  InsertStatement<Reviews> toInsert() {
    final rows = [
      for (final row in this)
        [
          Reviews.productId.set(row.productId),
          Reviews.customerId.set(row.customerId),
          Reviews.rating.set(row.rating),
          Reviews.createdAt.set(row.createdAt),
          Reviews.comment.set(row.comment),
        ],
    ];
    if (rows.isEmpty) {
      throw ArgumentError('toInsert() on an empty Iterable<ReviewWrite>: '
          'an INSERT needs at least one row.');
    }
    return insertInto(Reviews.table).values(rows);
  }
}
