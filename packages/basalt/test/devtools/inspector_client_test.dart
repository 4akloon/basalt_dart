import 'dart:convert';

import 'package:basalt/devtools_client.dart';
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

Map<String, Object?> _wire(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  group('InspectorClient', () {
    test('listInstances decodes instances', () async {
      final transport = _FakeTransport({
        'instances': [
          {'id': 'inst-0', 'name': 'db'},
        ],
      });

      final instances = await InspectorClient(transport).listInstances();

      expect(transport.method, BasaltExtension.listInstances.method);
      expect(instances.single.id, 'inst-0');
      expect(instances.single.name, 'db');
    });

    test('getSchema forwards the id and decodes the schema', () async {
      final transport = _FakeTransport(
        _wire(const SchemaDto([TableDto('t', [])]).toJson()),
      );

      final schema = await InspectorClient(transport).getSchema('inst-1');

      expect(transport.method, BasaltExtension.getSchema.method);
      expect(transport.args, {'id': 'inst-1'});
      expect(schema.tables.single.name, 't');
    });

    test('getTableData string-encodes scalars and json-encodes filters',
        () async {
      final transport = _FakeTransport(
        _wire(const TablePageDto(
          columns: [],
          rows: [],
          total: 0,
          limit: 25,
          offset: 5,
        ).toJson()),
      );

      await InspectorClient(transport).getTableData(
        'inst-0',
        table: 'orders',
        limit: 25,
        offset: 5,
        orderBy: 'name',
        desc: true,
        filters: const [ColumnFilter('status', 'eq', 'paid')],
      );

      expect(transport.method, BasaltExtension.getTableData.method);
      expect(transport.args!['limit'], '25');
      expect(transport.args!['offset'], '5');
      expect(transport.args!['orderBy'], 'name');
      expect(transport.args!['desc'], 'true');
      expect(
        jsonDecode(transport.args!['filters']!),
        [
          {'column': 'status', 'op': 'eq', 'value': 'paid'},
        ],
      );
    });

    test('getTableData omits optional args when unset', () async {
      final transport = _FakeTransport(
        _wire(const TablePageDto(
          columns: [],
          rows: [],
          total: 0,
          limit: 50,
          offset: 0,
        ).toJson()),
      );

      await InspectorClient(transport).getTableData('inst-0', table: 't');

      expect(transport.args!.containsKey('orderBy'), isFalse);
      expect(transport.args!.containsKey('desc'), isFalse);
      expect(transport.args!.containsKey('filters'), isFalse);
    });

    test('updateRow json-encodes key and changes', () async {
      final transport = _FakeTransport({'ok': true});

      await InspectorClient(transport).updateRow(
        'inst-0',
        table: 'users',
        key: {'id': 1},
        changes: {'name': 'Ann'},
      );

      expect(transport.method, BasaltExtension.updateRow.method);
      expect(jsonDecode(transport.args!['key']!), {'id': 1});
      expect(jsonDecode(transport.args!['changes']!), {'name': 'Ann'});
    });

    test('runSql omits empty params and decodes the result', () async {
      final transport = _FakeTransport(
        _wire(const SqlResultDto.write(affected: 1).toJson()),
      );

      final result =
          await InspectorClient(transport).runSql('inst-0', 'UPDATE t');

      expect(transport.method, BasaltExtension.runSql.method);
      expect(transport.args!.containsKey('params'), isFalse);
      expect(result.kind, 'write');
    });

    test('runSql json-encodes params when provided', () async {
      final transport = _FakeTransport(
        _wire(const SqlResultDto.read(columns: [], rows: []).toJson()),
      );

      await InspectorClient(transport)
          .runSql('inst-0', 'SELECT * FROM t WHERE id = ?', [1]);

      expect(jsonDecode(transport.args!['params']!), [1]);
    });
  });
}
