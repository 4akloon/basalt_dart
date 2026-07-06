import 'dart:async';

import 'package:basalt/basalt.dart';
import 'package:postgres/postgres.dart' as pg;

import 'postgres_dialect.dart';

/// Query-execution logic shared by [PostgresConnection] and the
/// transaction-scoped handle, parameterized over a `package:postgres`
/// [pg.Session]. `pg.Connection` and `pg.TxSession` both implement `pg.Session`,
/// so the same statement bodies run against either without change.
abstract class _PgSession implements Connection {
  pg.Session get _session;
  SqlDialect get _pgDialect;

  @override
  SqlDialect get dialect => _pgDialect;

  @override
  Future<List<R>> fetch<R>(SelectQuery<R> statement) async {
    final (sql, params) = QueryBuilder(_pgDialect).buildSelect(statement);
    final result = await _session.execute(sql, parameters: params);
    return [for (final row in result) statement.rowDecoder(row)];
  }

  @override
  Future<int> execute(WriteStatement statement) async {
    final (sql, params) = QueryBuilder(_pgDialect).buildWrite(statement);
    final result = await _session.execute(sql, parameters: params);
    return result.affectedRows;
  }

  @override
  Future<List<R>> executeReturning<R>(ReturningQuery<R> statement) async {
    final (sql, params) = QueryBuilder(_pgDialect)
        .buildWrite(statement.statement, returning: statement.returning);
    final result = await _session.execute(sql, parameters: params);
    return [for (final row in result) statement.rowDecoder(row)];
  }

  @override
  Future<void> executeSql(String sql, [List<Object?> params = const []]) async {
    if (params.isEmpty) {
      // Simple query mode allows multi-statement DDL (migrations).
      await _session.execute(sql, queryMode: pg.QueryMode.simple);
    } else {
      await _session.execute(sql, parameters: params);
    }
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final result = params.isEmpty
        ? await _session.execute(sql, queryMode: pg.QueryMode.simple)
        : await _session.execute(sql, parameters: params);
    return [for (final row in result) row.toColumnMap()];
  }

  @override
  Future<List<IntrospectedTable>> introspect() async {
    final tableRows = await _session.execute(
      'SELECT table_name FROM information_schema.tables '
      "WHERE table_schema = 'public' AND table_type = 'BASE TABLE' "
      "AND table_name <> '__basalt_schema_migrations' ORDER BY table_name",
      queryMode: pg.QueryMode.simple,
    );

    final tables = <IntrospectedTable>[];
    for (final tableRow in tableRows) {
      final tableName = tableRow[0]! as String;

      final columnRows = await _session.execute(
        'SELECT column_name, data_type, is_nullable '
        'FROM information_schema.columns '
        r'WHERE table_schema = $1 AND table_name = $2 ORDER BY ordinal_position',
        parameters: ['public', tableName],
      );

      final pkRows = await _session.execute(
        'SELECT kcu.column_name FROM information_schema.table_constraints tc '
        'JOIN information_schema.key_column_usage kcu '
        '  ON tc.constraint_name = kcu.constraint_name '
        '  AND tc.table_schema = kcu.table_schema '
        r'WHERE tc.table_schema = $1 AND tc.table_name = $2 '
        "AND tc.constraint_type = 'PRIMARY KEY'",
        parameters: ['public', tableName],
      );
      final pks = {for (final r in pkRows) r[0]! as String};

      final fkRows = await _session.execute(
        'SELECT kcu.column_name, ccu.table_name, ccu.column_name '
        'FROM information_schema.table_constraints tc '
        'JOIN information_schema.key_column_usage kcu '
        '  ON tc.constraint_name = kcu.constraint_name '
        '  AND tc.table_schema = kcu.table_schema '
        'JOIN information_schema.constraint_column_usage ccu '
        '  ON ccu.constraint_name = tc.constraint_name '
        '  AND ccu.table_schema = tc.table_schema '
        r'WHERE tc.table_schema = $1 AND tc.table_name = $2 '
        "AND tc.constraint_type = 'FOREIGN KEY'",
        parameters: ['public', tableName],
      );
      final fkByColumn = <String, ForeignKey>{
        for (final r in fkRows)
          r[0]! as String: ForeignKey(r[1]! as String, r[2]! as String),
      };

      tables.add(
        IntrospectedTable(tableName, [
          for (final c in columnRows)
            IntrospectedColumn(
              name: c[0]! as String,
              rawType: c[1]! as String,
              type: _columnType(c[1]! as String),
              isNullable: (c[2]! as String) == 'YES',
              isPrimaryKey: pks.contains(c[0]! as String),
              foreignKey: fkByColumn[c[0]! as String],
            ),
        ]),
      );
    }
    return tables;
  }

  /// Postgres `data_type` → canonical [ColumnType].
  static ColumnType _columnType(String pgType) {
    final t = pgType.toLowerCase();
    if (t.contains('bool')) return ColumnType.boolean;
    if (t.contains('int') || t.contains('serial')) return ColumnType.integer;
    if (t.contains('char') ||
        t == 'text' ||
        t.contains('json') ||
        t == 'uuid') {
      return ColumnType.text;
    }
    if (t.contains('real') ||
        t.contains('double') ||
        t.contains('numeric') ||
        t.contains('decimal') ||
        t.contains('float')) {
      return ColumnType.real;
    }
    if (t.contains('bytea')) return ColumnType.blob;
    if (t.contains('time') || t.contains('date')) return ColumnType.dateTime;
    return ColumnType.text;
  }
}

/// [Connection] backed by `package:postgres` (v3, async). Pairs the
/// [PostgresDialect] (`$N` placeholders) with the dialect-agnostic
/// [QueryBuilder]; it implements the exact same interface as the SQLite backend.
///
/// Transactions delegate to the driver's native `runTx`, which holds the
/// connection's operation lock for the transaction's lifetime — parallel
/// `transaction` calls queue rather than interleaving, and the driver throws if
/// the raw connection is used while a transaction is active. Inside a
/// transaction, use the handle passed to the callback, not this connection.
///
/// {@category getting-started}
final class PostgresConnection extends _PgSession {
  PostgresConnection._(this._conn, this._dialect);
  final pg.Connection _conn;
  final SqlDialect _dialect;
  int _savepointSeq = 0;

  /// Mints a savepoint name unique for this connection's lifetime, so no two
  /// live `SAVEPOINT`s can ever share a name (which would make `RELEASE` /
  /// `ROLLBACK TO SAVEPOINT` target the wrong one).
  String _nextSavepoint() => 'basalt_sp_${_savepointSeq++}';

  @override
  pg.Session get _session => _conn;

  @override
  SqlDialect get _pgDialect => _dialect;

  /// Opens a connection. Set [ssl] false for local/dev servers.
  static Future<PostgresConnection> open({
    required String host,
    int port = 5432,
    required String database,
    required String username,
    required String password,
    bool ssl = true,
  }) async {
    final conn = await pg.Connection.open(
      pg.Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: pg.ConnectionSettings(
        sslMode: ssl ? pg.SslMode.require : pg.SslMode.disable,
      ),
    );
    return PostgresConnection._(conn, const PostgresDialect());
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action) {
    return _conn.runTx((session) async {
      final tx = _PostgresTx(_dialect, session, _nextSavepoint);
      try {
        return await action(tx);
      } finally {
        tx._done = true;
      }
    });
  }

  @override
  Future<void> close() => _conn.close();
}

/// The transaction-scoped [Connection] handed to a `transaction` callback.
///
/// Statements run against the driver's [pg.TxSession] rather than the raw
/// connection. Calling [transaction] on this handle opens a nested `SAVEPOINT`
/// (postgres `TxSession` has no native nested `runTx`) — nesting is decided by
/// the handle's type, not by a shared counter. Nested transactions started on
/// the same handle are serialized through [_nested] and each gets a
/// connection-unique savepoint name (via [_nextSavepoint]), so sibling
/// savepoints never overlap or alias. The handle is single-use: once its
/// callback returns, every method throws [StateError].
final class _PostgresTx extends _PgSession {
  _PostgresTx(this._dialect, this._txSession, this._nextSavepoint);

  final SqlDialect _dialect;
  final pg.TxSession _txSession;
  final String Function() _nextSavepoint;
  final SerialLock _nested = SerialLock();
  bool _done = false;

  @override
  pg.Session get _session {
    if (_done) {
      throw StateError(
        'This transaction handle is no longer active; it must only be used '
        'inside the transaction callback it was passed to.',
      );
    }
    return _txSession;
  }

  @override
  SqlDialect get _pgDialect => _dialect;

  @override
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action) {
    final session = _session; // triggers the active-state check
    // Serialize sibling nested transactions so their savepoints can't overlap.
    return _nested.run(() async {
      final name = _nextSavepoint();
      await session.execute('SAVEPOINT $name');
      final inner = _PostgresTx(_dialect, _txSession, _nextSavepoint);
      try {
        final result = await action(inner);
        await session.execute('RELEASE SAVEPOINT $name');
        return result;
      } catch (_) {
        await session.execute('ROLLBACK TO SAVEPOINT $name');
        await session.execute('RELEASE SAVEPOINT $name');
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
