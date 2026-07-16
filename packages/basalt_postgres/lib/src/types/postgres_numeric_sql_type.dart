import 'package:basalt/basalt.dart';

import 'postgres_typed_sql_type.dart';

/// Postgres-native `numeric`/`decimal` codec that preserves full precision by
/// representing the value as an exact decimal `String` — the form
/// `package:postgres` returns for `numeric` columns (decoding to `double` would
/// be lossy).
///
/// Parse it with `package:decimal` or `num.parse` at the call site if you need
/// arithmetic. Emitted by the postgres adapter's `native_types: true` preset for
/// `numeric`/`decimal` columns; without the preset such columns fall back to a
/// (lossy) `double`. Wrap in `NullableSqlType` for nullable columns.
///
/// {@category getting-started}
final class PostgresNumericSqlType extends SqlType<String>
    implements PostgresTypedSqlType {
  const PostgresNumericSqlType();

  @override
  String? get postgresType => 'numeric';

  @override
  Object? encode(String input) => input;

  @override
  String decode(Object? encoded) => switch (encoded) {
        final String value => value,
        // Defensive: some drivers/paths may surface a num for numeric.
        final num value => value.toString(),
        _ => throw ArgumentError.value(
            encoded,
            'encoded',
            'Expected a numeric value as String',
          ),
      };
}
