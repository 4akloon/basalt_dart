import 'dart:async';

import 'package:basalt/devtools_client.dart';
import 'package:logging/logging.dart' as logging;
import 'package:mcp_dart/mcp_dart.dart';

import '../tools/basalt_tool.dart';
import '../tools/connect_tool.dart';
import '../tools/disconnect_tool.dart';
import '../tools/get_schema_tool.dart';
import '../tools/get_table_data_tool.dart';
import '../tools/list_instances_tool.dart';
import '../tools/run_sql_tool.dart';
import '../tools/tool_registrar.dart';
import '../tools/update_row_tool.dart';
import '../transport/vm_service_transport.dart';
import 'exit_signal.dart';
import 'logging_config.dart';

// Keep in sync with `version:` in pubspec.yaml.
const _version = '0.0.1';

const _instructions = '''
Basalt MCP lets AI agents inspect live Basalt database connections in a running
debug app via VM service extensions (ext.basalt.*).

Usage:
1. Register a connection in the app: BasaltDevTools.register(conn, name: 'main').
   The example app uses lib/main_debug.dart for this.
2. Run the app in debug mode: flutter run -t lib/main_debug.dart
3. Get the app's VM service URI (ws://127.0.0.1:PORT/ws) without asking the user
   via the Dart MCP server (dtd listDtdUris → dtd connect, which lists each
   connected app's URI), or copy it from the flutter run console.
4. Call connect with that URI (it changes on every hot restart / relaunch).
5. Call list_instances, then get_schema / get_table_data / run_sql.

Requires debug or profile mode — extensions are not available in release builds.
''';

/// Runs the Basalt MCP server on stdio.
///
/// {@category getting-started}
Future<int> runMcpServer({required String logLevel, String? logFile}) async {
  configureLogging(logLevel, logFile);
  final logger = logging.Logger('basalt_mcp');

  final transport = VmServiceTransport();
  final client = InspectorClient(transport);

  final server = McpServer(
    const Implementation(name: 'basalt-mcp', version: _version),
    options: const McpServerOptions(instructions: _instructions),
  );
  ToolRegistrar(server, logger).registerAll(_tools(transport, client));

  return _runStdioServer(server);
}

/// The tool set: connect/disconnect drive the [transport] lifecycle, the rest
/// go through the shared [client].
List<BasaltTool> _tools(VmServiceTransport transport, InspectorClient client) =>
    [
      ConnectTool(transport),
      DisconnectTool(transport),
      ListInstancesTool(client),
      GetSchemaTool(client),
      GetTableDataTool(client),
      UpdateRowTool(client),
      RunSqlTool(client),
    ];

Future<int> _runStdioServer(McpServer server) async {
  final logger = logging.Logger('main');
  final transport = StdioServerTransport();
  final exitSignal = ExitSignal();
  final stdinClosed = Completer<void>();

  server.server.onclose = () {
    if (!stdinClosed.isCompleted) stdinClosed.complete();
  };

  try {
    logger.fine('Running MCP server on stdio');
    await server.connect(transport);
    logger.info('Server started');
  } catch (e, st) {
    logger.severe('Error when starting the Stdio transport', e, st);
    exitSignal.dispose();
    return 1;
  }

  await _awaitShutdown(logger, exitSignal, stdinClosed);

  exitSignal.dispose();
  await server.close();
  await transport.close();
  logger.info('Stopped');
  return 0;
}

Future<void> _awaitShutdown(
  logging.Logger logger,
  ExitSignal exitSignal,
  Completer<void> stdinClosed,
) {
  var stopping = false;
  void logStop(String reason) {
    if (stopping) return;
    stopping = true;
    logger.info('$reason, stopping');
  }

  return Future.any([
    exitSignal.wait.then((signal) => logStop('Received ${signal.name}')),
    stdinClosed.future.then((_) => logStop('stdin closed')),
  ]);
}
