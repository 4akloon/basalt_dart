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
/// Every operation is routed through a single [SerialLock], so a transaction
/// holds the connection exclusively from `BEGIN` to `COMMIT`/`ROLLBACK`: parallel
/// `transaction` calls queue instead of interleaving, and no direct write can
/// slip inside an open transaction. Inside a transaction, use the transaction
/// handle passed to the callback — not the original connection — for further
/// statements; the connection's own methods would block on the held lock.
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
  final SerialLock _lock = SerialLock();
  int _savepointSeq = 0;

  /// Mints a savepoint name unique for this connection's lifetime, so no two
  /// live `SAVEPOINT`s can ever share a name (which would make `RELEASE` /
  /// `ROLLBACK TO` target the wrong one).
  String _nextSavepoint() => 'basalt_sp_${_savepointSeq++}';

  @override
  SqlDialect get dialect => _dialect;

  @override
  Future<List<R>> fetch<R>(SelectQuery<R> statement) =>
      _lock.run(() => _rawFetch(statement));

  @override
  Future<int> execute(WriteStatement statement) =>
      _lock.run(() => _rawExecute(statement));

  @override
  Future<List<R>> executeReturning<R>(ReturningQuery<R> statement) =>
      _lock.run(() => _rawExecuteReturning(statement));

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> params = const [],
  ]) =>
      _lock.run(() => _rawQueryRaw(sql, params));

  @override
  Future<void> executeSql(String sql, [List<Object?> params = const []]) =>
      _lock.run(() => _rawExecuteSql(sql, params));

  @override
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action) =>
      _lock.run(() async {
        _db.execute('BEGIN');
        final tx = _SqliteTx(this);
        try {
          final result = await action(tx);
          _db.execute('COMMIT');
          return result;
        } catch (_) {
          _db.execute('ROLLBACK');
          rethrow;
        } finally {
          tx._done = true;
        }
      });

  // Lock-free primitives. Public methods acquire [_lock]; [_SqliteTx] calls these
  // directly because the enclosing transaction already holds the lock.

  List<R> _rawFetch<R>(SelectQuery<R> statement) {
    final (sql, params) = QueryBuilder(_dialect).buildSelect(statement);
    final result = _db.select(sql, params);
    return [for (final row in result) statement.rowDecoder(row.values)];
  }

  int _rawExecute(WriteStatement statement) {
    final (sql, params) = QueryBuilder(_dialect).buildWrite(statement);
    final prepared = _db.prepare(sql);
    try {
      prepared.execute(params);
      return _db.updatedRows;
    } finally {
      prepared.close();
    }
  }

  List<R> _rawExecuteReturning<R>(ReturningQuery<R> statement) {
    final (sql, params) = QueryBuilder(_dialect)
        .buildWrite(statement.statement, returning: statement.returning);
    final result = _db.select(sql, params);
    return [for (final row in result) statement.rowDecoder(row.values)];
  }

  List<Map<String, Object?>> _rawQueryRaw(String sql, List<Object?> params) {
    final result = params.isEmpty ? _db.select(sql) : _db.select(sql, params);
    final names = result.columnNames;
    return [
      for (final row in result)
        {for (var i = 0; i < names.length; i++) names[i]: row.values[i]},
    ];
  }

  void _rawExecuteSql(String sql, List<Object?> params) {
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
  Future<List<IntrospectedTable>> introspect() => _lock.run(_rawIntrospect);

  List<IntrospectedTable> _rawIntrospect() {
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

/// The transaction-scoped [Connection] handed to a `transaction` callback.
///
/// It shares the parent's database but runs statements without re-acquiring the
/// connection lock (the enclosing transaction already holds it). Calling
/// [transaction] on this handle opens a nested `SAVEPOINT` — nesting is decided
/// by the handle's type, not by a shared counter, so it cannot be confused with
/// a concurrent root transaction. Nested transactions started on the same handle
/// are serialized through [_nested] and each gets a connection-unique savepoint
/// name, so sibling savepoints never overlap or alias. The handle is single-use:
/// once its callback returns, every method throws [StateError].
final class _SqliteTx implements Connection {
  _SqliteTx(this._parent);

  final SqliteConnection _parent;
  final SerialLock _nested = SerialLock();
  bool _done = false;

  /// The parent connection, or a [StateError] if this handle has outlived the
  /// callback it was passed to. Statements run on the parent's raw primitives
  /// (no relocking — the enclosing transaction already holds the lock).
  SqliteConnection get _active {
    if (_done) {
      throw StateError(
        'This transaction handle is no longer active; it must only be used '
        'inside the transaction callback it was passed to.',
      );
    }
    return _parent;
  }

  @override
  SqlDialect get dialect => _parent.dialect;

  @override
  Future<List<R>> fetch<R>(SelectQuery<R> statement) async =>
      _active._rawFetch(statement);

  @override
  Future<int> execute(WriteStatement statement) async =>
      _active._rawExecute(statement);

  @override
  Future<List<R>> executeReturning<R>(ReturningQuery<R> statement) async =>
      _active._rawExecuteReturning(statement);

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> params = const [],
  ]) async =>
      _active._rawQueryRaw(sql, params);

  @override
  Future<void> executeSql(
    String sql, [
    List<Object?> params = const [],
  ]) async =>
      _active._rawExecuteSql(sql, params);

  @override
  Future<List<IntrospectedTable>> introspect() async =>
      _active._rawIntrospect();

  @override
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action) {
    final parent = _active;
    // Serialize sibling nested transactions so their savepoints can't overlap.
    return _nested.run(() async {
      final name = parent._nextSavepoint();
      parent._db.execute('SAVEPOINT $name');
      final inner = _SqliteTx(parent);
      try {
        final result = await action(inner);
        parent._db.execute('RELEASE $name');
        return result;
      } catch (_) {
        parent._db
          ..execute('ROLLBACK TO $name')
          ..execute('RELEASE $name');
        rethrow;
      } finally {
        inner._done = true;
      }
    });
  }

  @override
  Future<void> close() async => throw StateError(
        'Cannot close a connection from within a transaction.',
      );
}
