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
        },
      );

  static const _jsonOverride = TypeOverride(
    dartType: 'Map<String, Object?>',
    sqlType: 'PostgresJsonbSqlType()',
    import: 'package:basalt_postgres/basalt_postgres.dart',
  );
}
