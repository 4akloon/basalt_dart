import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';

import 'models/column_filter.dart';
import 'models/instance_info.dart';
import 'models/schema_info.dart';
import 'models/sql_result.dart';
import 'models/table_page.dart';

/// Thin client over the `ext.basalt.*` VM service extensions registered by the
/// `basalt_devtools` runtime in the connected app.
class InspectorClient {
  Future<Map<String, dynamic>> _call(
    String method, [
    Map<String, String>? args,
  ]) async {
    final response =
        await serviceManager.callServiceExtensionOnMainIsolate(method, args: args);
    return response.json ?? const {};
  }

  Future<List<InstanceInfo>> listInstances() async {
    final json = await _call('ext.basalt.listInstances');
    final list = (json['instances'] as List?) ?? const [];
    return [for (final i in list) InstanceInfo.fromJson(i as Map)];
  }

  Future<SchemaInfo> getSchema(String id) async =>
      SchemaInfo.fromJson(await _call('ext.basalt.getSchema', {'id': id}));

  Future<TablePage> getTableData(
    String id,
    String table, {
    int limit = 50,
    int offset = 0,
    String? orderBy,
    bool desc = false,
    List<ColumnFilter> filters = const [],
  }) async {
    final args = {
      'id': id,
      'table': table,
      'limit': '$limit',
      'offset': '$offset',
      'orderBy': ?orderBy,
      if (desc) 'desc': 'true',
      if (filters.isNotEmpty)
        'filters': jsonEncode([for (final f in filters) f.toJson()]),
    };
    return TablePage.fromJson(await _call('ext.basalt.getTableData', args));
  }

  Future<void> updateRow(
    String id,
    String table, {
    required Map<String, Object?> key,
    required Map<String, Object?> changes,
  }) async {
    await _call('ext.basalt.updateRow', {
      'id': id,
      'table': table,
      'key': jsonEncode(key),
      'changes': jsonEncode(changes),
    });
  }

  Future<SqlResult> runSql(
    String id,
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final args = {
      'id': id,
      'sql': sql,
      if (params.isNotEmpty) 'params': jsonEncode(params),
    };
    return SqlResult.fromJson(await _call('ext.basalt.runSql', args));
  }
}
