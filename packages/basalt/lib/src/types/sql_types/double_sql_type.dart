import '../sql_type.dart';

/// {@category types}
final class DoubleSqlType extends SqlType<double> {
  const DoubleSqlType();

  @override
  String get sqlName => 'REAL';

  @override
  Object? encode(double input) => input;

  @override
  double decode(Object? encoded) => (encoded as num).toDouble();
}
