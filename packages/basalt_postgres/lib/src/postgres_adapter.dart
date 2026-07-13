import 'dart:async';

import 'package:basalt/basalt.dart';
import 'package:basalt/tooling.dart';

import 'postgres_connection.dart';
import 'postgres_endpoint.dart';

/// `BasaltAdapter` for the Postgres backend.
///
/// `database:` options are parsed by `PostgresEndpoint.fromOptions` — either a
/// single `url:` or manual `host`/`port`/`database`/`username`/`password`/`ssl`
/// keys. Select it in `basalt.yaml` with `backend: basalt_postgres`.
///
/// The opt-in [nativeTypeOverrides] preset (`native_types: true`) maps
/// `json`/`jsonb` columns to `Map<String, Object?>` via `PostgresJsonbSqlType`;
/// without it they emit as plain `String` columns.
///
/// {@category getting-started}
final class PostgresAdapter extends BasaltAdapter {
  const PostgresAdapter();

  @override
  String get name => 'postgres';

  @override
  Future<Connection> open(Map<String, Object?> options) {
    final endpoint = PostgresEndpoint.fromOptions(options);
    return PostgresConnection.open(
      host: endpoint.host,
      port: endpoint.port,
      database: endpoint.database,
      username: endpoint.username,
      password: endpoint.password,
      ssl: endpoint.ssl,
    );
  }

  @override
  Future<void> reset(Map<String, Object?> options) async {
    final connection = await open(options);
    try {
      await connection.executeSql(
        'DROP SCHEMA public CASCADE; CREATE SCHEMA public;',
      );
    } finally {
      await connection.close();
    }
  }

  @override
  SchemaTypeOverrides get nativeTypeOverrides => const SchemaTypeOverrides(
        byNative: {
          'json': _jsonOverride,
          'jsonb': _jsonOverride,
          'uuid': _uuidOverride,
          'numeric': _numericOverride,
          'decimal': _numericOverride,
          // Arrays: `information_schema` reports `data_type = ARRAY`, so
          // introspection keys array columns by their `udt_name` (the element
          // type with a leading underscore, e.g. `_int4` for `integer[]`).
          '_int2': _intArrayOverride,
          '_int4': _intArrayOverride,
          '_int8': _intArrayOverride,
          '_float4': _doubleArrayOverride,
          '_float8': _doubleArrayOverride,
          '_bool': _boolArrayOverride,
          '_text': _stringArrayOverride,
          '_varchar': _stringArrayOverride,
          '_bpchar': _stringArrayOverride,
          '_uuid': _stringArrayOverride,
          '_numeric': _stringArrayOverride,
        },
      );

  static const _import = 'package:basalt_postgres/basalt_postgres.dart';

  static const _jsonOverride = TypeOverride(
    dartType: 'Map<String, Object?>',
    sqlType: 'PostgresJsonbSqlType()',
    import: _import,
  );

  static const _uuidOverride = TypeOverride(
    dartType: 'String',
    sqlType: 'PostgresUuidSqlType()',
    import: _import,
  );

  static const _numericOverride = TypeOverride(
    dartType: 'String',
    sqlType: 'PostgresNumericSqlType()',
    import: _import,
  );

  static const _intArrayOverride = TypeOverride(
    dartType: 'List<int>',
    sqlType: 'PostgresArraySqlType<int>()',
    import: _import,
  );

  static const _doubleArrayOverride = TypeOverride(
    dartType: 'List<double>',
    sqlType: 'PostgresArraySqlType<double>()',
    import: _import,
  );

  static const _boolArrayOverride = TypeOverride(
    dartType: 'List<bool>',
    sqlType: 'PostgresArraySqlType<bool>()',
    import: _import,
  );

  static const _stringArrayOverride = TypeOverride(
    dartType: 'List<String>',
    sqlType: 'PostgresArraySqlType<String>()',
    import: _import,
  );
}
