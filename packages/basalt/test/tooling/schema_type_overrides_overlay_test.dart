import 'package:basalt/basalt.dart';
import 'package:basalt/tooling.dart';
import 'package:test/test.dart';

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

const _user = TypeOverride(dartType: 'User', sqlType: 'UserSqlType()');
const _preset = TypeOverride(dartType: 'Preset', sqlType: 'PresetSqlType()');

void main() {
  group('SchemaTypeOverrides.overlay', () {
    test('the receiver wins over the base for the same key', () {
      const user = SchemaTypeOverrides(byNative: {'jsonb': _user});
      const preset = SchemaTypeOverrides(byNative: {'jsonb': _preset});
      expect(user.overlay(preset).byNative['jsonb'], _user);
    });

    test('base entries survive for keys the receiver does not define', () {
      const user = SchemaTypeOverrides(byNative: {'jsonb': _user});
      const preset = SchemaTypeOverrides(
        byNative: {'uuid': _preset},
        byCanonical: {ColumnType.boolean: _preset},
      );
      final merged = user.overlay(preset);
      expect(merged.byNative['uuid'], _preset);
      expect(merged.byNative['jsonb'], _user);
      expect(merged.byCanonical[ColumnType.boolean], _preset);
    });

    test('level-first resolution: base column beats receiver canonical', () {
      // config.typeOverrides (canonical) overlaid over a preset (column).
      const user = SchemaTypeOverrides(byCanonical: {ColumnType.text: _user});
      const preset = SchemaTypeOverrides(byColumn: {'users.bio': _preset});
      final merged = user.overlay(preset);
      expect(merged.resolve('users', _col('bio')), _preset);
      // Other columns still fall through to the canonical entry.
      expect(merged.resolve('users', _col('name')), _user);
    });

    test('base native beats receiver canonical', () {
      const user = SchemaTypeOverrides(byCanonical: {ColumnType.text: _user});
      const preset = SchemaTypeOverrides(byNative: {'jsonb': _preset});
      final merged = user.overlay(preset);
      expect(merged.resolve('t', _col('x', rawType: 'jsonb')), _preset);
    });
  });

  group('SchemaTypeOverrides.resolve derives the nullable variant', () {
    const base = SchemaTypeOverrides(byNative: {'jsonb': _preset});

    test('non-null column returns the registered override', () {
      expect(base.resolve('t', _col('x', rawType: 'jsonb')), _preset);
    });

    test('nullable column wraps the codec and adds `?`', () {
      final resolved =
          base.resolve('t', _col('x', rawType: 'jsonb', nullable: true));
      expect(resolved?.dartType, 'Preset?');
      expect(resolved?.sqlType, 'NullableSqlType(PresetSqlType())');
    });

    test('nullable derivation preserves the import', () {
      const withImport = SchemaTypeOverrides(
        byNative: {
          'jsonb': TypeOverride(
            dartType: 'J',
            sqlType: 'JSqlType()',
            import: 'package:x/j.dart',
          ),
        },
      );
      final resolved =
          withImport.resolve('t', _col('x', rawType: 'jsonb', nullable: true));
      expect(resolved?.import, 'package:x/j.dart');
    });
  });
}
