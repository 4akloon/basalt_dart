import 'aggregate_join.dart';
import 'column_arg.dart';

/// One `@Agg` field bound to a private static select callback.
final class AggregateField {
  const AggregateField({
    required this.fieldName,
    required this.selectCall,
    this.zeroFallback = false,
  });
  final String fieldName;
  final String selectCall;
  final bool zeroFallback;
}

/// Metadata for a `@Queryable` class in aggregate (GROUP BY) mode.
final class AggregateInfo {
  const AggregateInfo({
    required this.fromMarker,
    required this.joins,
    required this.dimensions,
    required this.aggregates,
    this.orderByCall,
    this.orderDesc = false,
  });
  final String fromMarker;
  final List<AggregateJoin> joins;
  final List<ColumnArg> dimensions;
  final List<AggregateField> aggregates;
  final String? orderByCall;
  final bool orderDesc;
}
