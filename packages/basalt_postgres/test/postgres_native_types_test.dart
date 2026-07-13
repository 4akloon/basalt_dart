library;

import 'package:basalt/basalt.dart';
import 'package:basalt/tooling.dart';
import 'package:basalt_postgres/adapter.dart';
import 'package:basalt_postgres/basalt_postgres.dart';
import 'package:test/test.dart';

// Offline (no server): the native-type codecs and the adapter's `native_types`
// preset resolution for uuid / numeric / arrays.
void main() {
  group('codecs', () {
    test('uuid is a String pass-through', () {
      const t = PostgresUuidSqlType();
      const uuid = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
      expect(t.encode(uuid), uuid);
      expect(t.decode(uuid), uuid);
      expect(() => t.decode(42), throwsArgumentError);
    });

    test('numeric preserves the exact decimal string', () {
      const t = PostgresNumericSqlType();
      expect(t.encode('1234.5678'), '1234.5678');
      expect(t.decode('1234.5678'), '1234.5678');
      expect(t.decode(99), '99'); // defensive num fallback
      expect(() => t.decode(<int>[]), throwsArgumentError);
    });

    test('array is a typed List pass-through', () {
      const t = PostgresArraySqlType<int>();
      expect(t.encode([1, 2, 3]), [1, 2, 3]);
      expect(t.decode(<Object?>[1, 2, 3]), [1, 2, 3]);
      expect(t.decode(<Object?>[1, 2, 3]), isA<List<int>>());
      expect(() => t.decode('nope'), throwsArgumentError);
    });
  });

  group('native_types preset resolution', () {
    final overrides = const PostgresAdapter().nativeTypeOverrides;

    TypeOverride? resolve(String rawType, {bool nullable = false}) =>
        overrides.resolve(
          't',
          IntrospectedColumn(
            name: 'c',
            rawType: rawType,
            type: ColumnType.text,
            isNullable: nullable,
            isPrimaryKey: false,
          ),
        );

    test('maps uuid / numeric / decimal', () {
      expect(resolve('uuid')?.sqlType, 'PostgresUuidSqlType()');
      expect(resolve('numeric')?.dartType, 'String');
      expect(resolve('numeric')?.sqlType, 'PostgresNumericSqlType()');
      expect(resolve('decimal')?.sqlType, 'PostgresNumericSqlType()');
    });

    test('maps array udt_names to typed array codecs', () {
      expect(resolve('_int4')?.dartType, 'List<int>');
      expect(resolve('_int4')?.sqlType, 'PostgresArraySqlType<int>()');
      expect(resolve('_int8')?.sqlType, 'PostgresArraySqlType<int>()');
      expect(resolve('_text')?.dartType, 'List<String>');
      expect(resolve('_float8')?.sqlType, 'PostgresArraySqlType<double>()');
      expect(resolve('_bool')?.sqlType, 'PostgresArraySqlType<bool>()');
      expect(resolve('_uuid')?.dartType, 'List<String>');
    });

    test('nullable column derives the NullableSqlType variant', () {
      final o = resolve('_int4', nullable: true);
      expect(o?.dartType, 'List<int>?');
      expect(o?.sqlType, 'NullableSqlType(PostgresArraySqlType<int>())');
    });

    test('json/jsonb still resolve (unchanged)', () {
      expect(resolve('jsonb')?.sqlType, 'PostgresJsonbSqlType()');
    });
  });
}
