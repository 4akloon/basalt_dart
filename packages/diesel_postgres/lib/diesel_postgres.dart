/// Postgres backend for the Diesel Dart ORM.
///
/// Currently provides the dialect-level piece — [PostgresDialect], which uses
/// numbered `$N` placeholders. The driver-backed `Connection` and Postgres
/// introspection are WIP (they require `package:postgres` and a live database);
/// they'll implement the same `Connection` interface the SQLite backend does.
library;

export 'src/postgres_dialect.dart';
