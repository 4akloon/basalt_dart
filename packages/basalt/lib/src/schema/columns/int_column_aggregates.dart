part of '../table.dart';

/// Numeric aggregates for integer columns. SQLite returns NULL over an empty
/// set, so these decode to nullable Dart types.
extension IntColumnAggregates<Tbl> on TableColumn<int, Tbl> {
  Aggregate<int?> sum() => Aggregate(
      'SUM', node, 'sum_$name', const NullableSqlType<int>(IntSqlType()));
  Aggregate<double?> avg() => Aggregate(
      'AVG', node, 'avg_$name', const NullableSqlType<double>(DoubleSqlType()));
  Aggregate<int?> min() => Aggregate(
      'MIN', node, 'min_$name', const NullableSqlType<int>(IntSqlType()));
  Aggregate<int?> max() => Aggregate(
      'MAX', node, 'max_$name', const NullableSqlType<int>(IntSqlType()));
}
