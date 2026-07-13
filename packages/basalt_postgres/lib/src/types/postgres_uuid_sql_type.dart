import 'package:basalt/basalt.dart';

/// Postgres-native `uuid` codec, representing the value as its canonical
/// 36-character `String` (the form `package:postgres` reads and writes).
///
/// Emitted by the postgres adapter's `native_types: true` preset for `uuid`
/// columns; a schema using it imports `package:basalt_postgres`. Wrap in
/// `NullableSqlType` for nullable columns.
///
/// {@category getting-started}
final class PostgresUuidSqlType extends SqlType<String> {
  const PostgresUuidSqlType();

  @override
  Object? encode(String input) => input;

  @override
  String decode(Object? encoded) => switch (encoded) {
        final String uuid => uuid,
        _ => throw ArgumentError.value(
            encoded,
            'encoded',
            'Expected a uuid String',
          ),
      };
}
