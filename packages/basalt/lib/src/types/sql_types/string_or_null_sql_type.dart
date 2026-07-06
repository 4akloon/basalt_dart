import '../sql_type.dart';

/// {@category types}
final class StringOrNullSqlType extends SqlType<String?> {
  const StringOrNullSqlType();

  @override
  String get sqlName => 'TEXT';

  @override
  Object? encode(String? input) => input;

  @override
  String? decode(Object? encoded) => encoded as String?;
}
