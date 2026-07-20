import 'package:logging/logging.dart' as logging;
import 'package:mcp_dart/mcp_dart.dart';

import 'basalt_tool.dart';

/// Registers [BasaltTool]s on an [McpServer] behind a single error guard, so
/// every tool reports failures the same way instead of hand-rolling try/catch.
///
/// {@category getting-started}
final class ToolRegistrar {
  /// Creates a registrar targeting [_server], logging failures to [_logger].
  ToolRegistrar(this._server, this._logger);

  final McpServer _server;
  final logging.Logger _logger;

  /// Registers every tool in [tools].
  void registerAll(List<BasaltTool> tools) {
    for (final tool in tools) {
      _register(tool);
    }
  }

  void _register(BasaltTool tool) {
    _server.registerTool(
      tool.name,
      description: tool.description,
      annotations: tool.annotations,
      inputSchema: tool.inputSchema,
      callback: (args, extra) => _guard(tool, args),
    );
  }

  Future<CallToolResult> _guard(
    BasaltTool tool,
    Map<String, Object?> args,
  ) async {
    try {
      return await tool.call(args);
    } catch (err) {
      _logger.warning('Tool ${tool.name} failed', err);
      return CallToolResult(
        isError: true,
        content: [TextContent(text: err.toString())],
      );
    }
  }
}
