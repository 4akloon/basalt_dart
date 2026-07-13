/// Postgres backend for the Basalt Dart ORM.
///
/// Provides [PostgresDialect] (numbered `$N` placeholders, quoted identifiers)
/// and [PostgresConnection] — a driver-backed `Connection` on `package:postgres`
/// with transactions, nested `SAVEPOINT`s, and `information_schema`
/// introspection, implementing the same `Connection` interface as the SQLite
/// backend. Native-type codecs ([PostgresJsonbSqlType], [PostgresUuidSqlType],
/// [PostgresNumericSqlType], [PostgresArraySqlType]) cover `json`/`jsonb`,
/// `uuid`, `numeric`, and arrays, emitted by the adapter's `native_types` preset.
///
/// {@category getting-started}
library;

export 'src/postgres_connection.dart';
export 'src/postgres_dialect.dart';
export 'src/types/postgres_array_sql_type.dart';
export 'src/types/postgres_jsonb_sql_type.dart';
export 'src/types/postgres_numeric_sql_type.dart';
export 'src/types/postgres_uuid_sql_type.dart';
