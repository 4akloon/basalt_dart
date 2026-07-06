import '../sql_type.dart';

/// {@category types}
final class IntOrNullSqlType extends SqlType<int?> {
  const IntOrNullSqlType();

  @override
  String get sqlName => 'INTEGER';

  @override
  Object? encode(int? input) => input;

  @override
  int? decode(Object? encoded) =>
      encoded == null ? null : (encoded as num).toInt();
}
