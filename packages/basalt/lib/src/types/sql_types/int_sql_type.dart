import '../sql_type.dart';

/// {@category types}
final class IntSqlType extends SqlType<int> {
  const IntSqlType();

  @override
  String get sqlName => 'INTEGER';

  @override
  Object? encode(int input) => input;

  @override
  int decode(Object? encoded) => (encoded as num).toInt();
}
