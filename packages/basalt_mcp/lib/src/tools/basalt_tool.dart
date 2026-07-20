import 'package:mcp_dart/mcp_dart.dart';

/// One MCP tool exposed by the Basalt server: its declaration and behavior.
///
/// Each tool is its own class so it owns a single operation; [ToolRegistrar]
/// wires them onto the [McpServer] behind a uniform error guard.
///
/// {@category getting-started}
abstract interface class BasaltTool {
  /// Name the agent calls the tool by (e.g. `get_schema`).
  String get name;

  /// Human-readable description shown to the agent.
  String get description;

  /// Behavioral hints (read-only, destructive, ...).
  ToolAnnotations get annotations;

  /// Schema describing the tool's arguments.
  ToolInputSchema get inputSchema;

  /// Runs the tool against decoded [args] and returns its result.
  Future<CallToolResult> call(Map<String, Object?> args);
}
