/// Basalt MCP server — live database inspection for AI agents.
///
/// Connects to a running debug app's VM service and exposes its
/// `BasaltDevTools.register`ed connections through MCP tools backed by the
/// shared `package:basalt/devtools_client.dart` protocol.
library;

export 'src/exceptions/not_connected_exception.dart';
export 'src/exceptions/vm_service_extension_exception.dart';
export 'src/server/mcp_server_runner.dart';
export 'src/tools/basalt_tool.dart';
export 'src/tools/connect_tool.dart';
export 'src/tools/disconnect_tool.dart';
export 'src/tools/get_schema_tool.dart';
export 'src/tools/get_table_data_tool.dart';
export 'src/tools/list_instances_tool.dart';
export 'src/tools/run_sql_tool.dart';
export 'src/tools/tool_output.dart';
export 'src/tools/tool_registrar.dart';
export 'src/tools/update_row_tool.dart';
export 'src/transport/isolate_finder.dart';
export 'src/transport/vm_service_transport.dart';
