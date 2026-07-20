import 'package:basalt/devtools_client.dart';
import 'package:mcp_dart/mcp_dart.dart';

import 'basalt_tool.dart';
import 'tool_output.dart';

/// Lists the connections registered for inspection in the connected app.
final class ListInstancesTool implements BasaltTool {
  /// Creates the tool over [_client].
  ListInstancesTool(this._client);

  final InspectorClient _client;

  @override
  String get name => 'list_instances';

  @override
  String get description =>
      'Lists Basalt database connections registered via BasaltDevTools.register '
      'in the connected app.';

  @override
  ToolAnnotations get annotations => const ToolAnnotations(
        title: 'List Basalt Instances',
        readOnlyHint: true,
        idempotentHint: true,
      );

  @override
  ToolInputSchema get inputSchema => const ToolInputSchema(properties: {});

  @override
  Future<CallToolResult> call(Map<String, Object?> args) async {
    final instances = await _client.listInstances();
    return jsonResult({
      'instances': [for (final i in instances) i.toJson()]
    });
  }
}
