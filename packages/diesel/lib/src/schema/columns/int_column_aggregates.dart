part of '../table.dart';

/// Numeric aggregates for integer columns. SQLite returns NULL over an empty
/// set, so these decode to nullable Dart types.
extension IntColumnAggregates<Tbl> on TableColumn<int, Tbl> {
  Aggregate<int?> sum() =>
      Aggregate('SUM', node, 'sum_$name', SqlType.integerOrNull);
  Aggregate<double?> avg() =>
      Aggregate('AVG', node, 'avg_$name', SqlType.realOrNull);
  Aggregate<int?> min() =>
      Aggregate('MIN', node, 'min_$name', SqlType.integerOrNull);
  Aggregate<int?> max() =>
      Aggregate('MAX', node, 'max_$name', SqlType.integerOrNull);
}
