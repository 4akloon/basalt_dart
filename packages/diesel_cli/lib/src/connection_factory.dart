import 'package:diesel/diesel.dart';
import 'package:diesel_sqlite/diesel_sqlite.dart';

import 'config.dart';

/// Opens the backend [Connection] for [config], chosen by the URL scheme.
///
/// This is the one place that knows about concrete backends — commands work
/// against the abstract [Connection]. A future Postgres backend slots in here
/// (e.g. `postgres://` → `PostgresConnection`) without touching any command.
final class ConnectionFactory {
  const ConnectionFactory();

  Connection open(DieselConfig config) {
    final url = config.databaseUrl;
    if (url.startsWith('postgres://') || url.startsWith('postgresql://')) {
      throw UnsupportedError(
          'The Postgres backend is not implemented yet (DATABASE_URL: $url).');
    }
    return SqliteConnection.open(config.databasePath);
  }
}
