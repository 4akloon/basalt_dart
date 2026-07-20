import 'package:basalt/basalt.dart';

import '../dto/column_filter.dart';
import '../dto/table_page_dto.dart';
import 'inspector_exception.dart';
import 'json_codec.dart';
import 'param_binder.dart';
import 'schema_lookup.dart';
import 'where_clause.dart';

/// Reads one page of rows from a table through the raw-SQL escape hatch.
///
/// Identifiers (table, order-by, filter columns) are validated against the
/// introspected schema and quoted — they can't be parameterized — while filter
/// values are bound as parameters. [read]'s `limit` is clamped to `1..1000`.
final class TableReader {
  /// Creates a reader over [_conn].
  const TableReader(this._conn);

  final Connection _conn;

  /// Reads rows from [table], ordered/filtered/paged per the arguments.
  Future<TablePageDto> read({
    required String table,
    int limit = 50,
    int offset = 0,
    String? orderBy,
    bool desc = false,
    List<ColumnFilter> filters = const [],
  }) async {
    final target = await SchemaLookup(_conn).table(table);
    _requireOrderColumn(target, orderBy);

    final safeLimit = limit.clamp(1, 1000);
    final safeOffset = offset < 0 ? 0 : offset;
    final binder = ParamBinder(_conn.dialect);
    // WHERE is shared by the page + count queries (same params, same order).
    final where = WhereClause(target, binder).build(filters);
    final columns = [for (final c in target.columns) c.name];

    final rows = await _conn.queryRaw(
      _pageSql(table, where, orderBy, desc, safeLimit, safeOffset),
      binder.params,
    );
    return TablePageDto(
      columns: columns,
      rows: [for (final row in rows) _projectRow(row, columns)],
      total: await _count(table, where, binder.params),
      limit: safeLimit,
      offset: safeOffset,
    );
  }

  void _requireOrderColumn(IntrospectedTable target, String? orderBy) {
    if (orderBy != null && !target.columns.any((c) => c.name == orderBy)) {
      throw InspectorException('Unknown column: $orderBy');
    }
  }

  String _pageSql(
    String table,
    String where,
    String? orderBy,
    bool desc,
    int limit,
    int offset,
  ) {
    final sql = StringBuffer('SELECT * FROM ${_quote(table)}$where');
    if (orderBy != null) {
      sql.write(' ORDER BY ${_quote(orderBy)}${desc ? ' DESC' : ' ASC'}');
    }
    return (sql..write(' LIMIT $limit OFFSET $offset')).toString();
  }

  Future<int> _count(String table, String where, List<Object?> params) async {
    final rows = await _conn.queryRaw(
      'SELECT count(*) AS c FROM ${_quote(table)}$where',
      params,
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  // Project in schema-column order so the grid is deterministic regardless of
  // driver map ordering, coercing each cell to a JSON-safe value.
  List<Object?> _projectRow(Map<String, Object?> row, List<String> columns) =>
      [for (final name in columns) toJsonValue(row[name])];

  String _quote(String identifier) => _conn.dialect.quoteIdentifier(identifier);
}
