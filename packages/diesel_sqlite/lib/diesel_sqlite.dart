/// SQLite backend for Diesel — a concrete [SqlDialect] and a `sqlite3`-backed
/// [Connection]. Depends only on the dialect-agnostic core (`package:diesel`).
library;

export 'src/sqlite_connection.dart';
export 'src/sqlite_dialect.dart';
