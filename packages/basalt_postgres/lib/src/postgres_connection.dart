import 'dart:async';

import 'package:basalt/basalt.dart';
import 'package:postgres/postgres.dart' as pg;

import 'postgres_dialect.dart';

/// [Connection] backed by `package:postgres` (v3, async). Pairs the
/// [PostgresDialect] (`$N` placeholders) with the dialect-agnostic
/// [QueryBuilder]; it implements the exact same interface as the SQLite backend.
final class PostgresConnection implements Connection {

  PostgresConnection._(this._conn, this._dialect);
  final pg.Connection _conn;
  final SqlDialect _dialect;
  int _txDepth = 0;

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
  Future<List<R>> fetch<R>(SelectQuery<R> statement) async {
    final (sql, params) = QueryBuilder(_dialect).buildSelect(statement);
    final result = await _conn.execute(sql, parameters: params);
    return [for (final row in result) statement.rowDecoder(row)];
  }

  @override
  Future<int> execute(WriteStatement statement) async {
    final (sql, params) = QueryBuilder(_dialect).buildWrite(statement);
    final result = await _conn.execute(sql, parameters: params);
    return result.affectedRows;
  }

  @override
  Future<List<R>> executeReturning<R>(ReturningQuery<R> statement) async {
    final (sql, params) = QueryBuilder(_dialect)
        .buildWrite(statement.statement, returning: statement.returning);
    final result = await _conn.execute(sql, parameters: params);
    return [for (final row in result) statement.rowDecoder(row)];
  }

  @override
  Future<void> executeSql(String sql, [List<Object?> params = const []]) async {
    if (params.isEmpty) {
      // Simple query mode allows multi-statement DDL (migrations).
      await _conn.execute(sql, queryMode: pg.QueryMode.simple);
    } else {
      await _conn.execute(sql, parameters: params);
    }
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(String sql,
      [List<Object?> params = const [],]) async {
    final result = params.isEmpty
        ? await _conn.execute(sql, queryMode: pg.QueryMode.simple)
        : await _conn.execute(sql, parameters: params);
    return [for (final row in result) row.toColumnMap()];
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action) async {
    final isSavepoint = _txDepth > 0;
    final name = 'basalt_sp_$_txDepth';
    await _run(isSavepoint ? 'SAVEPOINT $name' : 'BEGIN');
    _txDepth++;
    try {
      final result = await action(this);
      await _run(isSavepoint ? 'RELEASE SAVEPOINT $name' : 'COMMIT');
      return result;
    } catch (_) {
      if (isSavepoint) {
        await _run('ROLLBACK TO SAVEPOINT $name');
        await _run('RELEASE SAVEPOINT $name');
      } else {
        await _run('ROLLBACK');
      }
      rethrow;
    } finally {
      _txDepth--;
    }
  }

  Future<void> _run(String sql) =>
      _conn.execute(sql, queryMode: pg.QueryMode.simple);

  @override
  Future<List<IntrospectedTable>> introspect() async {
    final tableRows = await _conn.execute(
      'SELECT table_name FROM information_schema.tables '
      "WHERE table_schema = 'public' AND table_type = 'BASE TABLE' "
      "AND table_name <> '__basalt_schema_migrations' ORDER BY table_name",
      queryMode: pg.QueryMode.simple,
    );

    final tables = <IntrospectedTable>[];
    for (final tableRow in tableRows) {
      final tableName = tableRow[0]! as String;

      final columnRows = await _conn.execute(
        'SELECT column_name, data_type, is_nullable '
        'FROM information_schema.columns '
        r'WHERE table_schema = $1 AND table_name = $2 ORDER BY ordinal_position',
        parameters: ['public', tableName],
      );

      final pkRows = await _conn.execute(
        'SELECT kcu.column_name FROM information_schema.table_constraints tc '
        'JOIN information_schema.key_column_usage kcu '
        '  ON tc.constraint_name = kcu.constraint_name '
        '  AND tc.table_schema = kcu.table_schema '
        r'WHERE tc.table_schema = $1 AND tc.table_name = $2 '
        "AND tc.constraint_type = 'PRIMARY KEY'",
        parameters: ['public', tableName],
      );
      final pks = {for (final r in pkRows) r[0]! as String};

      final fkRows = await _conn.execute(
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

      tables.add(IntrospectedTable(tableName, [
        for (final c in columnRows)
          IntrospectedColumn(
            name: c[0]! as String,
            rawType: c[1]! as String,
            type: _columnType(c[1]! as String),
            isNullable: (c[2]! as String) == 'YES',
            isPrimaryKey: pks.contains(c[0]! as String),
            foreignKey: fkByColumn[c[0]! as String],
          ),
      ]),);
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

  @override
  Future<void> close() => _conn.close();
}
