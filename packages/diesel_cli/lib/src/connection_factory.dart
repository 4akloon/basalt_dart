import 'package:diesel/diesel.dart';
import 'package:diesel_postgres/diesel_postgres.dart';
import 'package:diesel_sqlite/diesel_sqlite.dart';

import 'config.dart';

/// Opens the backend [Connection] for [config], chosen by the URL scheme.
///
/// This is the one place that knows about concrete backends — commands work
/// against the abstract [Connection]. `postgres://` / `postgresql://` URLs open a
/// [PostgresConnection]; anything else is treated as a SQLite path.
final class ConnectionFactory {
  const ConnectionFactory();

  Future<Connection> open(DieselConfig config) async {
    final url = config.databaseUrl;
    if (url.startsWith('postgres://') || url.startsWith('postgresql://')) {
      final uri = Uri.parse(url);
      final credentials = uri.userInfo.split(':');
      final database = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (database.isEmpty) {
        throw ArgumentError('Postgres URL must include a database name: $url');
      }
      return PostgresConnection.open(
        host: uri.host.isEmpty ? 'localhost' : uri.host,
        port: uri.hasPort ? uri.port : 5432,
        database: database,
        username: credentials.isNotEmpty && credentials.first.isNotEmpty
            ? Uri.decodeComponent(credentials.first)
            : 'postgres',
        password: credentials.length > 1
            ? Uri.decodeComponent(credentials[1])
            : '',
        // Default to SSL; opt out for local/dev with `?sslmode=disable`.
        ssl: uri.queryParameters['sslmode'] != 'disable',
      );
    }
    return SqliteConnection.open(config.databasePath);
  }
}
