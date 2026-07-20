import 'package:mcp_dart/mcp_dart.dart';

import '../transport/vm_service_transport.dart';
import 'basalt_tool.dart';
import 'tool_output.dart';

/// Opens the VM service connection to a running debug app.
final class ConnectTool implements BasaltTool {
  /// Creates the tool over [_transport].
  ConnectTool(this._transport);

  final VmServiceTransport _transport;

  @override
  String get name => 'connect';

  @override
  String get description =>
      'Connects to a running debug app via its VM service URI '
      '(e.g. ws://127.0.0.1:9101/ws). Call this before any other tool. Get the '
      'URI without asking the user via the Dart MCP server (dtd listDtdUris to '
      'pick the repo-rooted instance, then dtd connect, which lists each '
      'connected app VM service URI), or copy it from the `flutter run` console '
      'output. The URI changes on every hot restart or relaunch. The app must '
      'call BasaltDevTools.register(conn) so ext.basalt.* extensions are '
      'available.';

  @override
  ToolAnnotations get annotations =>
      const ToolAnnotations(title: 'Connect to App');

  @override
  ToolInputSchema get inputSchema => ToolInputSchema(
        properties: {
          'uri': JsonSchema.string(
            description:
                'VM service WebSocket URI (ws://.../ws), from the Dart '
                'MCP DTD discovery or the flutter run output.',
          ),
        },
        required: ['uri'],
      );

  @override
  Future<CallToolResult> call(Map<String, Object?> args) async {
    final uri = args['uri'] as String;
    await _transport.connect(uri);
    return textResult('Connected to app at $uri');
  }
}
