import 'dart:io';

import 'package:basalt/basalt.dart';
import 'package:basalt_cli/basalt_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Parses [yaml] to the `SchemaTypeOverrides` its `types:` node describes, the
/// way `BasaltConfig.load` does.
SchemaTypeOverrides _overrides(String yaml) => const SchemaTypeOverridesParser()
    .parse((loadYaml(yaml) as YamlMap)['types']);

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
  group('SchemaTypeOverridesParser', () {
    test('null node yields empty overrides', () {
      expect(const SchemaTypeOverridesParser().parse(null).isEmpty, isTrue);
    });

    test('parses columns, native (normalized) and canonical', () {
      final overrides = _overrides('''
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
  canonical:
    dateTime:
      dart_type: "DateTime"
      sql_type: "UtcDateTimeSqlType()"
''');

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
        overrides.byCanonical[ColumnType.dateTime]?.sqlType,
        'UtcDateTimeSqlType()',
      );
    });

    test('resolve honours precedence and derives nullability', () {
      final overrides = _overrides('''
types:
  canonical:
    text: { dart_type: "Can", sql_type: "CanSqlType()" }
  native:
    text:
      dart_type: "Nat"
      sql_type: "NatSqlType()"
  columns:
    users.name: { dart_type: "Col", sql_type: "ColSqlType()" }
''');

      expect(overrides.resolve('users', _col('name'))?.dartType, 'Col');
      expect(overrides.resolve('users', _col('bio'))?.dartType, 'Nat');
      final nullable = overrides.resolve('users', _col('bio', nullable: true));
      expect(nullable?.dartType, 'Nat?');
      expect(nullable?.sqlType, 'NullableSqlType(NatSqlType())');
      // A column with no rawType/native match falls through to canonical.
      expect(
        overrides.resolve('t', _col('x', rawType: ''))?.dartType,
        'Can',
      );
    });

    test('native match ignores a size/precision suffix', () {
      final overrides = _overrides('''
types:
  native:
    varchar: { dart_type: "S", sql_type: "SSqlType()" }
''');

      expect(
        overrides.resolve('t', _col('x', rawType: 'VARCHAR(255)'))?.dartType,
        'S',
      );
    });

    group('rejects malformed config with StateError', () {
      void bad(String yaml) => expect(
            () => _overrides(yaml),
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
      test(
        'removed nullable: variant',
        () => bad('types:\n  native:\n    x:\n'
            '      dart_type: "A"\n      sql_type: "A()"\n'
            '      nullable: { dart_type: "A?", sql_type: "AN()" }'),
      );
    });
  });

  group('BasaltConfig.load', () {
    String write(String yaml) {
      final tmp = Directory.systemTemp.createTempSync('basalt_cfg_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path = p.join(tmp.path, 'basalt.yaml');
      File(path).writeAsStringSync(yaml);
      return path;
    }

    test('parses the types: block', () {
      final path = write('''
backend: basalt_sqlite
database:
  path: x.db
types:
  native:
    jsonb: { dart_type: "M", sql_type: "MSqlType()" }
''');

      final config = BasaltConfig.load(environment: {}, configPath: path);
      expect(config.typeOverrides.byNative['jsonb']?.sqlType, 'MSqlType()');
    });

    test('a config without a types: block has empty overrides', () {
      final path = write('backend: basalt_sqlite\ndatabase:\n  path: x.db\n');

      final config = BasaltConfig.load(environment: {}, configPath: path);
      expect(config.typeOverrides.isEmpty, isTrue);
      expect(config.database, {'path': 'x.db'});
    });

    test('backend is required and read when set', () {
      expect(
        () => BasaltConfig.load(
          environment: {},
          configPath: write('database:\n  path: x.db\n'),
        ),
        throwsA(
          isStateError.having(
            (e) => e.message,
            'message',
            contains('No backend configured'),
          ),
        ),
      );

      final withBackend = BasaltConfig.load(
        environment: {},
        configPath: write('''
backend: basalt_postgres
database:
  url: postgres://localhost/app
'''),
      );
      expect(withBackend.backend, 'basalt_postgres');
    });

    test('native_types defaults to false and parses as bool', () {
      final config = BasaltConfig.load(
        environment: {},
        configPath: write('''
backend: basalt_sqlite
database: { path: x.db }
native_types: true
'''),
      );
      expect(config.nativeTypes, isTrue);

      final off = BasaltConfig.load(
        environment: {},
        configPath: write('backend: basalt_sqlite\ndatabase: { path: x.db }\n'),
      );
      expect(off.nativeTypes, isFalse);
    });

    test('DATABASE_URL env overrides database.url', () {
      final config = BasaltConfig.load(
        environment: {'DATABASE_URL': 'postgres://env/db'},
        configPath: write('''
backend: basalt_postgres
database:
  url: postgres://yaml/db
  ssl: false
'''),
      );
      expect(config.database['url'], 'postgres://env/db');
      expect(config.database['ssl'], false);
    });

    test('DATABASE_URL alone configures the database', () {
      final config = BasaltConfig.load(
        environment: {'DATABASE_URL': 'postgres://env/db'},
        configPath: write('backend: basalt_postgres\n'),
      );
      expect(config.database, {'url': 'postgres://env/db'});
    });

    test('no database at all throws', () {
      expect(
        () => BasaltConfig.load(
          environment: {},
          configPath: write('backend: basalt_sqlite\n'),
        ),
        throwsStateError,
      );
    });

    test('legacy database_url: key is rejected with a migration hint', () {
      expect(
        () => BasaltConfig.load(
          environment: {},
          configPath: write('database_url: x.db\n'),
        ),
        throwsA(
          isStateError.having(
            (e) => e.message,
            'message',
            contains('no longer supported'),
          ),
        ),
      );
    });

    test('invalid backend: value throws', () {
      expect(
        () => BasaltConfig.load(
          environment: {},
          configPath: write('backend: "Not A Package"\ndatabase: {path: x}\n'),
        ),
        throwsStateError,
      );
    });
  });
}
