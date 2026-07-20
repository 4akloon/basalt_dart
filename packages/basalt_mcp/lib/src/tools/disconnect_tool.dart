import 'package:mcp_dart/mcp_dart.dart';

import '../transport/vm_service_transport.dart';
import 'basalt_tool.dart';
import 'tool_output.dart';

/// Tears down the current VM service connection.
final class DisconnectTool implements BasaltTool {
  /// Creates the tool over [_transport].
  DisconnectTool(this._transport);

  final VmServiceTransport _transport;

  @override
  String get name => 'disconnect';

  @override
  String get description =>
      'Disconnects from the currently connected app. Call connect again before '
      'using other tools.';

  @override
  ToolAnnotations get annotations =>
      const ToolAnnotations(title: 'Disconnect from App');

  @override
  ToolInputSchema get inputSchema => const ToolInputSchema(properties: {});

  @override
  Future<CallToolResult> call(Map<String, Object?> args) async {
    await _transport.disconnect();
    return textResult('Disconnected from app');
  }
}
