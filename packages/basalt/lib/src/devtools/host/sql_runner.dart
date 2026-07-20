import 'package:basalt/basalt.dart';

import '../dto/sql_result_dto.dart';
import 'json_codec.dart';

/// Runs an arbitrary SQL statement (dev-only; reads *and* writes) and shapes the
/// outcome into a [SqlResultDto].
///
/// Statements that yield rows (`SELECT`/`WITH`/`PRAGMA`/`EXPLAIN`/`VALUES`, or
/// anything with a `RETURNING` clause) go through [Connection.queryRaw];
/// everything else through [Connection.executeSql]. Result rows are capped at
/// [_maxRows]. Failures are returned as an error result, never thrown.
final class SqlRunner {
  /// Creates a runner over [_conn].
  const SqlRunner(this._conn);

  final Connection _conn;

  static const _maxRows = 1000;

  static final _readLead = RegExp(
    r'^\s*(select|with|pragma|explain|show|values|table)\b',
    caseSensitive: false,
  );
  static final _returning = RegExp(r'\breturning\b', caseSensitive: false);

  /// Runs [sql] with bound [params].
  Future<SqlResultDto> run(String sql,
      [List<Object?> params = const []]) async {
    try {
      if (_returnsRows(sql)) {
        return _read(await _conn.queryRaw(sql, params));
      }
      await _conn.executeSql(sql, params);
      return const SqlResultDto.write();
    } catch (e) {
      return SqlResultDto.error(e.toString());
    }
  }

  bool _returnsRows(String sql) =>
      _readLead.hasMatch(sql) || _returning.hasMatch(sql);

  SqlResultDto _read(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) {
      return const SqlResultDto.read(columns: [], rows: []);
    }
    final columns = rows.first.keys.toList();
    final truncated = rows.length > _maxRows;
    final limited = truncated ? rows.sublist(0, _maxRows) : rows;
    return SqlResultDto.read(
      columns: columns,
      rows: [
        for (final row in limited)
          [for (final c in columns) toJsonValue(row[c])],
      ],
      truncated: truncated,
    );
  }
}
