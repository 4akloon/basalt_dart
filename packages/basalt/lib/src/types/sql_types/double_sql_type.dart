import '../sql_type.dart';

/// {@category types}
final class DoubleSqlType extends SqlType<double> {
  const DoubleSqlType();

  @override
  Object? encode(double input) => input;

  @override
  double decode(Object? encoded) => (encoded as num).toDouble();
}
