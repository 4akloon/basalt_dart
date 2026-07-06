import 'dart:io';

import 'package:basalt/basalt.dart';
import 'package:basalt_cli/basalt_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Parses [yaml] and returns its `types:` node, as `BasaltConfig.load` would
/// hand it to [SchemaTypeOverrides.fromYaml].
Object? _types(String yaml) => (loadYaml(yaml) as YamlMap)['types'];

IntrospectedColumn _col(
  String name, {
  ColumnType type = ColumnType.text,
  String rawType = 'TEXT',
  bool nullable = false,
}) =>
    IntrospectedColumn(
      name: name,
      type: type,
      rawType: rawType,
      isNullable: nullable,
      isPrimaryKey: false,
    );

void main() {
  group('SchemaTypeOverrides.fromYaml', () {
    test('null node yields empty overrides', () {
      expect(SchemaTypeOverrides.fromYaml(null).isEmpty, isTrue);
    });

    test('parses columns, native (normalized) and canonical + nullable', () {
      final overrides = SchemaTypeOverrides.fromYaml(
        _types('''
types:
  columns:
    users.metadata:
      dart_type: "UserMeta"
      sql_type: "UserMetaSqlType()"
      import: "package:app/user_meta.dart"
  native:
    JSONB:
      dart_type: "Map<String, Object?>"
      sql_type: "JsonMapSqlType()"
      nullable:
        dart_type: "Map<String, Object?>?"
        sql_type: "JsonMapOrNullSqlType()"
  canonical:
    dateTime:
      dart_type: "DateTime"
      sql_type: "UtcDateTimeSqlType()"
'''),
      );

      expect(overrides.isEmpty, isFalse);
      expect(
        overrides.byColumn['users.metadata']?.sqlType,
        'UserMetaSqlType()',
      );
      expect(
        overrides.byColumn['users.metadata']?.import,
        'package:app/user_meta.dart',
      );
      // Native key is normalized to lowercase.
      expect(overrides.byNative['jsonb']?.dartType, 'Map<String, Object?>');
      expect(
        overrides.byNativeNullable['jsonb']?.sqlType,
        'JsonMapOrNullSqlType()',
      );
      expect(
        overrides.byCanonical[ColumnType.dateTime]?.sqlType,
        'UtcDateTimeSqlType()',
      );
    });

    test('resolve honours precedence and nullability', () {
      final overrides = SchemaTypeOverrides.fromYaml(
        _types('''
types:
  canonical:
    text: { dart_type: "Can", sql_type: "CanSqlType()" }
  native:
    text:
      dart_type: "Nat"
      sql_type: "NatSqlType()"
      nullable: { dart_type: "Nat?", sql_type: "NatOrNullSqlType()" }
  columns:
    users.name: { dart_type: "Col", sql_type: "ColSqlType()" }
'''),
      );

      expect(overrides.resolve('users', _col('name'))?.dartType, 'Col');
      expect(overrides.resolve('users', _col('bio'))?.dartType, 'Nat');
      expect(
        overrides.resolve('users', _col('bio', nullable: true))?.dartType,
        'Nat?',
      );
      // A column with no rawType/native match falls through to canonical.
      expect(
        overrides.resolve('t', _col('x', rawType: ''))?.dartType,
        'Can',
      );
    });

    test('native match ignores a size/precision suffix', () {
      final overrides = SchemaTypeOverrides.fromYaml(
        _types('''
types:
  native:
    varchar: { dart_type: "S", sql_type: "SSqlType()" }
'''),
      );

      expect(
        overrides.resolve('t', _col('x', rawType: 'VARCHAR(255)'))?.dartType,
        'S',
      );
    });

    group('rejects malformed config with StateError', () {
      void bad(String yaml) => expect(
            () => SchemaTypeOverrides.fromYaml(_types(yaml)),
            throwsStateError,
          );

      test('types is not a mapping', () => bad('types: 5'));
      test('unknown sub-key', () => bad('types:\n  colums: {}'));
      test(
        'missing sql_type',
        () => bad('types:\n  native:\n    x: { dart_type: "A" }'),
      );
      test(
        'missing dart_type',
        () => bad('types:\n  native:\n    x: { sql_type: "A()" }'),
      );
      test(
        'unknown canonical type',
        () => bad(
          'types:\n  canonical:\n    money: { dart_type: "A", sql_type: "A()" }',
        ),
      );
    });
  });

  group('BasaltConfig.load', () {
    test('parses the types: block', () {
      final tmp = Directory.systemTemp.createTempSync('basalt_cfg_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path = p.join(tmp.path, 'basalt.yaml');
      File(path).writeAsStringSync('''
database_url: x.db
types:
  native:
    jsonb: { dart_type: "M", sql_type: "MSqlType()" }
''');

      final config = BasaltConfig.load(environment: {}, configPath: path);
      expect(config.typeOverrides.byNative['jsonb']?.sqlType, 'MSqlType()');
    });

    test('a config without a types: block has empty overrides', () {
      final tmp = Directory.systemTemp.createTempSync('basalt_cfg_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path = p.join(tmp.path, 'basalt.yaml');
      File(path).writeAsStringSync('database_url: x.db\n');

      final config = BasaltConfig.load(environment: {}, configPath: path);
      expect(config.typeOverrides.isEmpty, isTrue);
    });
  });
}
