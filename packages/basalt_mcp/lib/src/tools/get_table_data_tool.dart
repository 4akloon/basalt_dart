import 'dart:convert';

import 'package:basalt/devtools_client.dart';
import 'package:mcp_dart/mcp_dart.dart';

import 'basalt_tool.dart';
import 'tool_output.dart';

/// Reads one page of rows from a table on a registered instance.
final class GetTableDataTool implements BasaltTool {
  /// Creates the tool over [_client].
  GetTableDataTool(this._client);

  final InspectorClient _client;

  @override
  String get name => 'get_table_data';

  @override
  String get description =>
      'Reads one page of rows from a table on a registered instance. Filters '
      'are JSON: [{"column":"name","op":"eq","value":"x"}].';

  @override
  ToolAnnotations get annotations =>
      const ToolAnnotations(title: 'Get Table Data', readOnlyHint: true);

  @override
  ToolInputSchema get inputSchema => ToolInputSchema(
        properties: {
          'id': JsonSchema.string(description: 'Instance id.'),
          'table': JsonSchema.string(description: 'Table name.'),
          'limit': JsonSchema.integer(description: 'Max rows (1..1000).'),
          'offset': JsonSchema.integer(description: 'Row offset.'),
          'orderBy': JsonSchema.string(description: 'Column to sort by.'),
          'desc': JsonSchema.boolean(description: 'Sort descending.'),
          'filters': JsonSchema.string(
            description: 'JSON array of column filters.',
          ),
        },
        required: ['id', 'table'],
      );

  @override
  Future<CallToolResult> call(Map<String, Object?> args) async {
    final page = await _client.getTableData(
      args['id'] as String,
      table: args['table'] as String,
      limit: args['limit'] as int? ?? 50,
      offset: args['offset'] as int? ?? 0,
      orderBy: args['orderBy'] as String?,
      desc: args['desc'] as bool? ?? false,
      filters: _filters(args['filters']),
    );
    return jsonResult(page.toJson());
  }

  List<ColumnFilter> _filters(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    return [
      for (final f in jsonDecode(raw) as List) ColumnFilter.fromJson(f as Map),
    ];
  }
}
