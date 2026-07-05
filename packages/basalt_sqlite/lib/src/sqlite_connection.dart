import 'dart:async';

import 'package:basalt/basalt.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_dialect.dart';

/// `Connection` backed by `package:sqlite3` (synchronous, FFI).
///
/// The driver is synchronous, so these methods complete their work eagerly and
/// return already-resolved futures — the async signatures exist so an async
/// backend (Postgres) can implement the same `Connection` interface unchanged.
///
/// {@category getting-started}
final class SqliteConnection implements Connection {
  SqliteConnection._(this._db, this._dialect);

  /// Opens an in-memory database — ideal for tests.
  factory SqliteConnection.memory() =>
      SqliteConnection._(sqlite3.openInMemory(), const SqliteDialect());

  /// Opens (or creates) a database file at [path].
  factory SqliteConnection.open(String path) =>
      SqliteConnection._(sqlite3.open(path), const SqliteDialect());
  final Database _db;
  final SqlDialect _dialect;
  int _txDepth = 0;

  @override
  SqlDialect get dialect => _dialect;

  @override
  Future<List<R>> fetch<R>(SelectQuery<R> statement) async {
    final (sql, params) = QueryBuilder(_dialect).buildSelect(statement);
    final result = _db.select(sql, params);
    return [for (final row in result) statement.rowDecoder(row.values)];
  }

  @override
  Future<int> execute(WriteStatement statement) async {
    final (sql, params) = QueryBuilder(_dialect).buildWrite(statement);
    final prepared = _db.prepare(sql);
    try {
      prepared.execute(params);
      return _db.updatedRows;
    } finally {
      prepared.close();
    }
  }

  @override
  Future<List<R>> executeReturning<R>(ReturningQuery<R> statement) async {
    final (sql, params) = QueryBuilder(_dialect)
        .buildWrite(statement.statement, returning: statement.returning);
    final result = _db.select(sql, params);
    return [for (final row in result) statement.rowDecoder(row.values)];
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final result = params.isEmpty ? _db.select(sql) : _db.select(sql, params);
    final names = result.columnNames;
    return [
      for (final row in result)
        {for (var i = 0; i < names.length; i++) names[i]: row.values[i]},
    ];
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
      prepared.close();
    }
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action) async {
    final isSavepoint = _txDepth > 0;
    final name = 'basalt_sp_$_txDepth';
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
  Future<List<IntrospectedTable>> introspect() async {
    final tableRows = _db.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' "
      "AND name <> '__basalt_schema_migrations' ORDER BY name",
    );

    final tables = <IntrospectedTable>[];
    for (final tableRow in tableRows) {
      final tableName = tableRow['name'] as String;
      final columnRows = _db.select('PRAGMA table_info("$tableName")');
      final fkRows = _db.select('PRAGMA foreign_key_list("$tableName")');

      final fkByColumn = <String, ForeignKey>{
        for (final fk in fkRows)
          fk['from'] as String:
              ForeignKey(fk['table'] as String, (fk['to'] as String?) ?? ''),
      };

      tables.add(
        IntrospectedTable(tableName, [
          for (final c in columnRows)
            IntrospectedColumn(
              name: c['name'] as String,
              rawType: (c['type'] as String?) ?? '',
              type: _affinity((c['type'] as String?) ?? ''),
              isNullable: (c['notnull'] as int) == 0,
              isPrimaryKey: (c['pk'] as int) != 0,
              foreignKey: fkByColumn[c['name'] as String],
            ),
        ]),
      );
    }
    return tables;
  }

  /// SQLite type affinity → canonical [ColumnType]. SQLite has no native
  /// boolean/timestamp, so those are indistinguishable from integer/text here.
  static ColumnType _affinity(String declared) {
    final t = declared.toUpperCase();
    if (t.contains('INT')) return ColumnType.integer;
    if (t.contains('CHAR') || t.contains('CLOB') || t.contains('TEXT')) {
      return ColumnType.text;
    }
    if (t.contains('REAL') || t.contains('FLOA') || t.contains('DOUB')) {
      return ColumnType.real;
    }
    if (t.contains('BLOB') || t.isEmpty) return ColumnType.blob;
    return ColumnType.text; // NUMERIC / unknown
  }

  @override
  Future<void> close() async => _db.close();
}
