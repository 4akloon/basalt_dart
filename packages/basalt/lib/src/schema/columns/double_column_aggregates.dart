part of '../table.dart';

/// Numeric aggregates for double columns.
extension DoubleColumnAggregates<Tbl> on TableColumn<double, Tbl> {
  Aggregate<double?> sum() => Aggregate(
      'SUM', node, 'sum_$name', const NullableSqlType<double>(DoubleSqlType()));
  Aggregate<double?> avg() => Aggregate(
      'AVG', node, 'avg_$name', const NullableSqlType<double>(DoubleSqlType()));
  Aggregate<double?> min() => Aggregate(
      'MIN', node, 'min_$name', const NullableSqlType<double>(DoubleSqlType()));
  Aggregate<double?> max() => Aggregate(
      'MAX', node, 'max_$name', const NullableSqlType<double>(DoubleSqlType()));
}
