// ignore_for_file: avoid_print
//
// Manual smoke test against a running debug app:
//   flutter run -d macos -t lib/main_debug.dart
//   dart run tool/smoke.dart ws://127.0.0.1:PORT/ws

import 'dart:convert';
import 'dart:io';

import 'package:basalt/devtools_client.dart';
import 'package:basalt_mcp/basalt_mcp.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/smoke.dart <vm-service-ws-uri>');
    exitCode = 1;
    return;
  }

  final transport = VmServiceTransport();
  final client = InspectorClient(transport);
  final uri = args.single;

  print('Connecting to $uri...');
  await transport.connect(uri);
  print('Connected.\n');

  final instances = await client.listInstances();
  print(
      'list_instances:\n${_pretty([for (final i in instances) i.toJson()])}\n');
  if (instances.isEmpty) {
    print('No instances registered — did BasaltDevTools.register run?');
    return;
  }

  final id = instances.first.id;
  print('Using instance id=$id\n');

  final schema = await client.getSchema(id);
  print('get_schema:\n${_pretty(schema.toJson())}\n');
  if (schema.tables.isEmpty) {
    print('No tables in schema.');
    return;
  }

  final tableName = schema.tables.first.name;
  print('get_table_data(table=$tableName, limit=3):\n');
  final page = await client.getTableData(id, table: tableName, limit: 3);
  print(_pretty(page.toJson()));

  await transport.disconnect();
  print('\nSmoke test OK.');
}

String _pretty(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
