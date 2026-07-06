part of '../table.dart';

/// Numeric aggregates for double columns.
extension DoubleColumnAggregates<Tbl> on TableColumn<double, Tbl> {
  Aggregate<double?> sum() =>
      Aggregate('SUM', node, 'sum_$name', const DoubleOrNullSqlType());
  Aggregate<double?> avg() =>
      Aggregate('AVG', node, 'avg_$name', const DoubleOrNullSqlType());
  Aggregate<double?> min() =>
      Aggregate('MIN', node, 'min_$name', const DoubleOrNullSqlType());
  Aggregate<double?> max() =>
      Aggregate('MAX', node, 'max_$name', const DoubleOrNullSqlType());
}
