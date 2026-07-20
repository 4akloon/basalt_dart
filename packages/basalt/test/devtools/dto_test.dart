import 'dart:convert';

import 'package:basalt/devtools_client.dart';
import 'package:test/test.dart';

/// Simulates a VM service round-trip: `toJson` encoded, then decoded the way a
/// client actually receives it (nested `List<dynamic>` / `Map<String, dynamic>`).
Map<String, Object?> wire(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  group('DTO fromJson survives a real wire round-trip', () {
    test('TablePageDto rebuilds columns and rows from dynamic lists', () {
      const page = TablePageDto(
        columns: ['id', 'name'],
        rows: [
          [1, 'a'],
          [2, null],
        ],
        total: 2,
        limit: 50,
        offset: 0,
      );

      final decoded = TablePageDto.fromJson(wire(page.toJson()));

      expect(decoded.columns, ['id', 'name']);
      expect(decoded.rows, [
        [1, 'a'],
        [2, null],
      ]);
      expect(decoded.total, 2);
    });

    test('SqlResultDto.read preserves truncated', () {
      const result = SqlResultDto.read(
        columns: ['c'],
        rows: [
          [1],
        ],
        truncated: true,
      );

      final decoded = SqlResultDto.fromJson(wire(result.toJson()));

      expect(decoded.isRead, isTrue);
      expect(decoded.columns, ['c']);
      expect(decoded.truncated, isTrue);
    });

    test('SqlResultDto.write and .error round-trip', () {
      final write = SqlResultDto.fromJson(
        wire(const SqlResultDto.write(affected: 3).toJson()),
      );
      expect(write.kind, 'write');
      expect(write.affected, 3);

      final error = SqlResultDto.fromJson(
        wire(const SqlResultDto.error('boom').toJson()),
      );
      expect(error.isError, isTrue);
      expect(error.error, 'boom');
    });

    test('SchemaDto keeps nested columns and foreign keys', () {
      const schema = SchemaDto([
        TableDto('orders', [
          ColumnDto(
            name: 'id',
            type: 'integer',
            rawType: 'INTEGER',
            isNullable: false,
            isPrimaryKey: true,
          ),
          ColumnDto(
            name: 'customer_id',
            type: 'integer',
            rawType: 'INTEGER',
            isNullable: false,
            isPrimaryKey: false,
            foreignKey: ForeignKeyDto('customers', 'id'),
          ),
        ]),
      ]);

      final decoded = SchemaDto.fromJson(wire(schema.toJson()));

      expect(decoded.tables.single.name, 'orders');
      expect(decoded.tables.single.columns.last.foreignKey?.table, 'customers');
    });

    test('RegisteredInstance round-trips id and name', () {
      final decoded = RegisteredInstance.fromJson(
        wire(const RegisteredInstance(id: 'inst-0', name: 'db').toJson()),
      );
      expect(decoded.id, 'inst-0');
      expect(decoded.name, 'db');
    });
  });
}
