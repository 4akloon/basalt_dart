import 'package:basalt/devtools_client.dart';
import 'package:mcp_dart/mcp_dart.dart';

import 'basalt_tool.dart';
import 'tool_output.dart';

/// Introspects the schema of a registered instance.
final class GetSchemaTool implements BasaltTool {
  /// Creates the tool over [_client].
  GetSchemaTool(this._client);

  final InspectorClient _client;

  @override
  String get name => 'get_schema';

  @override
  String get description =>
      'Introspects the schema for a registered Basalt instance (tables, '
      'columns, foreign keys).';

  @override
  ToolAnnotations get annotations => const ToolAnnotations(
        title: 'Get Schema',
        readOnlyHint: true,
        idempotentHint: true,
      );

  @override
  ToolInputSchema get inputSchema => ToolInputSchema(
        properties: {
          'id': JsonSchema.string(
            description: 'Instance id from list_instances.',
          ),
        },
        required: ['id'],
      );

  @override
  Future<CallToolResult> call(Map<String, Object?> args) async {
    final schema = await _client.getSchema(args['id'] as String);
    return jsonResult(schema.toJson());
  }
}
