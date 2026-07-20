import 'dart:convert';

import 'package:basalt/devtools_client.dart';
import 'package:mcp_dart/mcp_dart.dart';

import 'basalt_tool.dart';
import 'tool_output.dart';

/// Runs raw SQL on a registered instance.
final class RunSqlTool implements BasaltTool {
  /// Creates the tool over [_client].
  RunSqlTool(this._client);

  final InspectorClient _client;

  @override
  String get name => 'run_sql';

  @override
  String get description =>
      'Runs raw SQL on a registered instance. [params] is a JSON array of bound '
      'values. Read queries return rows (max 1000); writes return affected row '
      'count.';

  @override
  ToolAnnotations get annotations => const ToolAnnotations(title: 'Run SQL');

  @override
  ToolInputSchema get inputSchema => ToolInputSchema(
        properties: {
          'id': JsonSchema.string(description: 'Instance id.'),
          'sql': JsonSchema.string(description: 'SQL statement.'),
          'params': JsonSchema.string(
            description: 'Optional JSON array of bound parameters.',
          ),
        },
        required: ['id', 'sql'],
      );

  @override
  Future<CallToolResult> call(Map<String, Object?> args) async {
    final result = await _client.runSql(
      args['id'] as String,
      args['sql'] as String,
      _params(args['params']),
    );
    return jsonResult(result.toJson());
  }

  List<Object?> _params(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List).cast<Object?>();
  }
}
