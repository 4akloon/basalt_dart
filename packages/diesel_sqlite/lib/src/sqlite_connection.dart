import 'dart:async';

import 'package:diesel/diesel.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_dialect.dart';

/// [Connection] backed by `package:sqlite3` (synchronous, FFI).
///
/// The driver is synchronous, so these methods complete their work eagerly and
/// return already-resolved futures — the async signatures exist so an async
/// backend (Postgres) can implement the same [Connection] interface unchanged.
final class SqliteConnection implements Connection {
  final Database _db;
  final SqlDialect _dialect;
  int _txDepth = 0;

  SqliteConnection._(this._db, this._dialect);

  /// Opens an in-memory database — ideal for tests.
  factory SqliteConnection.memory() =>
      SqliteConnection._(sqlite3.openInMemory(), const SqliteDialect());

  /// Opens (or creates) a database file at [path].
  factory SqliteConnection.open(String path) =>
      SqliteConnection._(sqlite3.open(path), const SqliteDialect());

  @override
  Future<List<R>> fetch<R>(SelectStatement<R, dynamic> statement) async {
    final (sql, params) = QueryBuilder(_dialect).buildSelect(statement);
    final result = _db.select(sql, params);
    return [for (final row in result) statement.decodeRow(row.values)];
  }

  @override
  Future<int> execute(WriteStatement statement) async {
    final (sql, params) = QueryBuilder(_dialect).buildWrite(statement);
    final prepared = _db.prepare(sql);
    try {
      prepared.execute(params);
      return _db.updatedRows;
    } finally {
      prepared.dispose();
    }
  }

  @override
  Future<void> executeSql(String sql, [List<Object?> params = const []]) async {
    if (params.isEmpty) {
      _db.execute(sql);
      return;
    }
    final prepared = _db.prepare(sql);
    try {
      prepared.execute(params);
    } finally {
      prepared.dispose();
    }
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action) async {
    final isSavepoint = _txDepth > 0;
    final name = 'diesel_sp_$_txDepth';
    _db.execute(isSavepoint ? 'SAVEPOINT $name' : 'BEGIN');
    _txDepth++;
    try {
      final result = await action(this);
      _db.execute(isSavepoint ? 'RELEASE $name' : 'COMMIT');
      return result;
    } catch (_) {
      if (isSavepoint) {
        _db
          ..execute('ROLLBACK TO $name')
          ..execute('RELEASE $name');
      } else {
        _db.execute('ROLLBACK');
      }
      rethrow;
    } finally {
      _txDepth--;
    }
  }

  @override
  Future<void> close() async => _db.dispose();
}
