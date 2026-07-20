import 'dart:convert';

import 'package:basalt/devtools_client.dart';
import 'package:basalt_mcp/basalt_mcp.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:test/test.dart';

/// Records the last call and replays a canned, wire-shaped response.
final class _FakeTransport implements InspectorTransport {
  _FakeTransport(this._response);

  final Map<String, Object?> _response;
  String? method;
  Map<String, String>? args;

  @override
  Future<Map<String, Object?>> call(String method, Map<String, String> args) {
    this.method = method;
    this.args = args;
    return Future.value(_response);
  }
}

/// A transport that always fails — to exercise error propagation.
final class _ThrowingTransport implements InspectorTransport {
  @override
  Future<Map<String, Object?>> call(String method, Map<String, String> args) =>
      throw StateError('boom');
}

Map<String, Object?> _wire(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

String _textOf(CallToolResult result) =>
    (result.content.single as TextContent).text;

void main() {
  group('data tools', () {
    test('ListInstancesTool wraps instances as JSON', () async {
      final transport = _FakeTransport({
        'instances': [
          {'id': 'inst-0', 'name': 'db'},
        ],
      });
      final tool = ListInstancesTool(InspectorClient(transport));

      final result = await tool.call(const {});

      expect(transport.method, BasaltExtension.listInstances.method);
      expect(jsonDecode(_textOf(result)), {
        'instances': [
          {'id': 'inst-0', 'name': 'db'},
        ],
      });
    });

    test('GetSchemaTool forwards the id and returns schema JSON', () async {
      final transport = _FakeTransport(
        _wire(const SchemaDto([TableDto('users', [])]).toJson()),
      );
      final tool = GetSchemaTool(InspectorClient(transport));

      final result = await tool.call({'id': 'inst-0'});

      expect(transport.args, {'id': 'inst-0'});
      final json = jsonDecode(_textOf(result)) as Map<String, Object?>;
      expect((json['tables'] as List).single, containsPair('name', 'users'));
    });

    test('GetTableDataTool applies defaults and encodes filters', () async {
      final transport = _FakeTransport(
        _wire(const TablePageDto(
          columns: [],
          rows: [],
          total: 0,
          limit: 50,
          offset: 0,
        ).toJson()),
      );
      final tool = GetTableDataTool(InspectorClient(transport));

      await tool.call({
        'id': 'inst-0',
        'table': 'users',
        'filters': '[{"column":"name","op":"eq","value":"Ann"}]',
      });

      expect(transport.method, BasaltExtension.getTableData.method);
      expect(transport.args!['limit'], '50');
      expect(transport.args!['offset'], '0');
      expect(jsonDecode(transport.args!['filters']!), [
        {'column': 'name', 'op': 'eq', 'value': 'Ann'},
      ]);
    });

    test('UpdateRowTool parses key and changes JSON objects', () async {
      final transport = _FakeTransport({'ok': true});
      final tool = UpdateRowTool(InspectorClient(transport));

      final result = await tool.call({
        'id': 'inst-0',
        'table': 'users',
        'key': '{"id":1}',
        'changes': '{"name":"Ann"}',
      });

      expect(jsonDecode(transport.args!['key']!), {'id': 1});
      expect(jsonDecode(transport.args!['changes']!), {'name': 'Ann'});
      expect(_textOf(result), 'Row updated');
    });

    test('RunSqlTool parses params and returns the result JSON', () async {
      final transport = _FakeTransport(
        _wire(const SqlResultDto.write(affected: 1).toJson()),
      );
      final tool = RunSqlTool(InspectorClient(transport));

      final result =
          await tool.call({'id': 'inst-0', 'sql': 'SELECT 1', 'params': '[1]'});

      expect(jsonDecode(transport.args!['params']!), [1]);
      expect(jsonDecode(_textOf(result)), containsPair('kind', 'write'));
    });

    test('a tool propagates transport errors to its caller', () {
      final tool = GetSchemaTool(InspectorClient(_ThrowingTransport()));
      expect(() => tool.call({'id': 'inst-0'}), throwsA(isA<StateError>()));
    });
  });

  group('VmServiceTransport', () {
    test('throws NotConnectedException before connect', () {
      expect(
        () => VmServiceTransport().call(
          BasaltExtension.listInstances.method,
          const {},
        ),
        throwsA(isA<NotConnectedException>()),
      );
    });
  });

  group('tool output', () {
    test('jsonResult pretty-prints', () {
      expect(_textOf(jsonResult({'tables': []})), '{\n  "tables": []\n}');
    });

    test('textResult wraps plain text', () {
      expect(_textOf(textResult('hi')), 'hi');
    });
  });
}
