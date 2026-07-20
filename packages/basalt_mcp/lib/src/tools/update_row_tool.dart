import 'dart:convert';

import 'package:basalt/devtools_client.dart';
import 'package:mcp_dart/mcp_dart.dart';

import 'basalt_tool.dart';
import 'tool_output.dart';

/// Updates one row by key on a registered instance.
final class UpdateRowTool implements BasaltTool {
  /// Creates the tool over [_client].
  UpdateRowTool(this._client);

  final InspectorClient _client;

  @override
  String get name => 'update_row';

  @override
  String get description =>
      'Updates one row by primary key on a registered instance. [key] and '
      '[changes] are JSON objects keyed by column name.';

  @override
  ToolAnnotations get annotations =>
      const ToolAnnotations(title: 'Update Row', destructiveHint: true);

  @override
  ToolInputSchema get inputSchema => ToolInputSchema(
        properties: {
          'id': JsonSchema.string(description: 'Instance id.'),
          'table': JsonSchema.string(description: 'Table name.'),
          'key': JsonSchema.string(
            description: 'JSON object with primary-key columns.',
          ),
          'changes': JsonSchema.string(
            description: 'JSON object of column updates.',
          ),
        },
        required: ['id', 'table', 'key', 'changes'],
      );

  @override
  Future<CallToolResult> call(Map<String, Object?> args) async {
    await _client.updateRow(
      args['id'] as String,
      table: args['table'] as String,
      key: _object(args['key']),
      changes: _object(args['changes']),
    );
    return textResult('Row updated');
  }

  Map<String, Object?> _object(Object? raw) =>
      (jsonDecode(raw as String) as Map).cast<String, Object?>();
}
