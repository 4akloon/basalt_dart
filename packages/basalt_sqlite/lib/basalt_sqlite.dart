/// SQLite backend for Basalt — a concrete [SqlDialect] and a `sqlite3`-backed
/// [Connection]. Depends only on the dialect-agnostic core (`package:basalt`).
library;

export 'src/sqlite_connection.dart';
export 'src/sqlite_dialect.dart';
