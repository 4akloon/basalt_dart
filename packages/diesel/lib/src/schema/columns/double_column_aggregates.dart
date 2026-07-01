part of '../table.dart';

/// Numeric aggregates for double columns.
extension DoubleColumnAggregates<Tbl> on TableColumn<double, Tbl> {
  Aggregate<double?> sum() =>
      Aggregate('SUM', node, 'sum_$name', SqlType.realOrNull);
  Aggregate<double?> avg() =>
      Aggregate('AVG', node, 'avg_$name', SqlType.realOrNull);
  Aggregate<double?> min() =>
      Aggregate('MIN', node, 'min_$name', SqlType.realOrNull);
  Aggregate<double?> max() =>
      Aggregate('MAX', node, 'max_$name', SqlType.realOrNull);
}
