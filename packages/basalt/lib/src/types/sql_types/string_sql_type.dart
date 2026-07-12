import '../sql_type.dart';

/// {@category types}
final class StringSqlType extends SqlType<String> {
  const StringSqlType();

  @override
  Object? encode(String input) => input;

  @override
  String decode(Object? encoded) => encoded as String;
}
