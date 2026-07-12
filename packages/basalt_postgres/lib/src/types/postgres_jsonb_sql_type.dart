import 'dart:convert';

import 'package:basalt/basalt.dart';

/// Postgres-native `json`/`jsonb` codec for JSON-object columns.
///
/// Encodes to a JSON string parameter (the server infers `json`/`jsonb` from
/// the column context); decodes either the `Map` the driver returns for
/// `json`/`jsonb` columns or a raw JSON string. Wrap in `NullableSqlType` for
/// nullable columns.
///
/// Emitted by the postgres adapter's `native_types: true` preset — a schema
/// using it imports `package:basalt_postgres` and is no longer
/// backend-portable.
///
/// {@category getting-started}
final class PostgresJsonbSqlType extends SqlType<Map<String, Object?>> {
  const PostgresJsonbSqlType();

  @override
  Object? encode(Map<String, Object?> input) => jsonEncode(input);

  @override
  Map<String, Object?> decode(Object? encoded) => switch (encoded) {
        final Map<String, Object?> map => map,
        final Map map => map.cast<String, Object?>(),
        final String json => (jsonDecode(json) as Map).cast<String, Object?>(),
        _ => throw ArgumentError.value(
            encoded,
            'encoded',
            'Expected a JSON object (Map) or a JSON string',
          ),
      };
}
