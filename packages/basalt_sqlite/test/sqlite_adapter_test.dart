import 'dart:io';

import 'package:basalt_sqlite/adapter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('SqliteAdapter options', () {
    const sqlite = SqliteAdapter();

    test('opens a database file from path:', () async {
      final tmp = Directory.systemTemp.createTempSync('sqlite_adapter_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path = p.join(tmp.path, 'test.db');

      final connection = await sqlite.open({'path': path});
      await connection.executeSql('CREATE TABLE t (id INTEGER PRIMARY KEY)');
      await connection.close();
      expect(File(path).existsSync(), isTrue);
    });

    test('supports :memory:', () async {
      final connection = await sqlite.open({'path': ':memory:'});
      await connection.executeSql('CREATE TABLE t (id INTEGER PRIMARY KEY)');
      await connection.close();
    });

    test('missing path throws ArgumentError naming the adapter', () {
      expect(
        () => sqlite.open(const {}),
        throwsA(
          isArgumentError.having(
            (e) => e.message,
            'message',
            contains('sqlite adapter'),
          ),
        ),
      );
    });

    test('unknown option key throws', () {
      expect(
        () => sqlite.open(const {'path': 'x.db', 'url': 'sqlite://x.db'}),
        throwsArgumentError,
      );
    });
  });

  group('SqliteAdapter.reset', () {
    test('deletes the database file', () async {
      final tmp = Directory.systemTemp.createTempSync('sqlite_adapter_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path = p.join(tmp.path, 'test.db');
      final options = {'path': path};

      const sqlite = SqliteAdapter();
      final connection = await sqlite.open(options);
      await connection.executeSql('CREATE TABLE t (id INTEGER PRIMARY KEY)');
      await connection.close();
      expect(File(path).existsSync(), isTrue);

      await sqlite.reset(options);
      expect(File(path).existsSync(), isFalse);
      // Resetting a database that is already gone is a no-op, not an error.
      await sqlite.reset(options);
    });
  });

  group('SqliteAdapter type preset', () {
    test('maps declared BOOLEAN/DATETIME to portable core types', () {
      final preset = const SqliteAdapter().typeOverrides;
      expect(preset.byNative['boolean']?.dartType, 'bool');
      expect(preset.byNative['bool']?.sqlType, 'BooleanSqlType()');
      expect(preset.byNative['datetime']?.dartType, 'DateTime');
      expect(preset.byNative['timestamp']?.sqlType, 'DateTimeSqlType()');
      // Nullable variants are derived, not registered.
      expect(
        preset.byNative['boolean']?.asNullable().sqlType,
        'NullableSqlType(BooleanSqlType())',
      );
      expect(preset.byNative['datetime']?.asNullable().dartType, 'DateTime?');
      // Portable tier must never pull in a backend import.
      for (final override in preset.byNative.values) {
        expect(override.import, isNull);
      }
    });

    test('native tier is empty for sqlite', () {
      expect(const SqliteAdapter().nativeTypeOverrides.isEmpty, isTrue);
    });
  });
}
