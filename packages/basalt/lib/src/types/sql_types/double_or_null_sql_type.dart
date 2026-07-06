import '../sql_type.dart';

/// {@category types}
final class DoubleOrNullSqlType extends SqlType<double?> {
  const DoubleOrNullSqlType();

  @override
  String get sqlName => 'REAL';

  @override
  Object? encode(double? input) => input;

  @override
  double? decode(Object? encoded) =>
      encoded == null ? null : (encoded as num).toDouble();
}
