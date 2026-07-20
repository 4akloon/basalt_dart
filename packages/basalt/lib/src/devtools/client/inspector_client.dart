import 'dart:convert';

import '../dto/column_filter.dart';
import '../dto/registered_instance.dart';
import '../dto/schema_dto.dart';
import '../dto/sql_result_dto.dart';
import '../dto/table_page_dto.dart';
import '../protocol/basalt_extension.dart';
import 'inspector_transport.dart';

/// Typed client for the `ext.basalt.*` inspector protocol.
///
/// The transport-agnostic mirror of `InspectorService`: it encodes arguments,
/// delegates the round-trip to an [InspectorTransport], and decodes each
/// response into the shared DTOs. Consumers (the DevTools extension, the MCP
/// server) reuse this class and supply only their own [InspectorTransport].
final class InspectorClient {
  /// Creates a client that talks over the given [InspectorTransport].
  const InspectorClient(this._transport);

  final InspectorTransport _transport;

  /// Lists the connections registered for inspection in the target app.
  Future<List<RegisteredInstance>> listInstances() async {
    final json = await _call(BasaltExtension.listInstances);
    final list = (json['instances'] as List?) ?? const [];
    return [for (final i in list) RegisteredInstance.fromJson(_asMap(i))];
  }

  /// Introspects the schema of instance [id].
  Future<SchemaDto> getSchema(String id) async =>
      SchemaDto.fromJson(await _call(BasaltExtension.getSchema, {'id': id}));

  /// Reads one page of rows from [table] on instance [id].
  Future<TablePageDto> getTableData(
    String id, {
    required String table,
    int limit = 50,
    int offset = 0,
    String? orderBy,
    bool desc = false,
    List<ColumnFilter> filters = const [],
  }) async {
    final json = await _call(
      BasaltExtension.getTableData,
      _tableDataArgs(id, table, limit, offset, orderBy, desc, filters),
    );
    return TablePageDto.fromJson(json);
  }

  /// Updates a single row of [table] on instance [id]: `changes` where `key`.
  Future<void> updateRow(
    String id, {
    required String table,
    required Map<String, Object?> key,
    required Map<String, Object?> changes,
  }) async {
    await _call(BasaltExtension.updateRow, {
      'id': id,
      'table': table,
      'key': jsonEncode(key),
      'changes': jsonEncode(changes),
    });
  }

  /// Runs an arbitrary SQL statement on instance [id] with bound [params].
  Future<SqlResultDto> runSql(
    String id,
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final args = {
      'id': id,
      'sql': sql,
      if (params.isNotEmpty) 'params': jsonEncode(params),
    };
    return SqlResultDto.fromJson(await _call(BasaltExtension.runSql, args));
  }

  Future<Map<String, Object?>> _call(
    BasaltExtension extension, [
    Map<String, String> args = const {},
  ]) =>
      _transport.call(extension.method, args);

  static Map<String, String> _tableDataArgs(
    String id,
    String table,
    int limit,
    int offset,
    String? orderBy,
    bool desc,
    List<ColumnFilter> filters,
  ) =>
      {
        'id': id,
        'table': table,
        'limit': '$limit',
        'offset': '$offset',
        if (orderBy != null) 'orderBy': orderBy,
        if (desc) 'desc': 'true',
        if (filters.isNotEmpty)
          'filters': jsonEncode([for (final f in filters) f.toJson()]),
      };

  static Map<String, Object?> _asMap(Object? value) =>
      (value as Map).cast<String, Object?>();
}
