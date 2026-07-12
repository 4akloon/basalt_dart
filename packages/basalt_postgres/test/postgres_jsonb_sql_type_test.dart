import 'package:basalt/basalt.dart';
import 'package:basalt_postgres/basalt_postgres.dart';
import 'package:test/test.dart';

void main() {
  group('PostgresJsonbSqlType', () {
    const type = PostgresJsonbSqlType();

    test('encodes to a JSON string', () {
      expect(type.encode({'a': 1, 'b': 'x'}), '{"a":1,"b":"x"}');
    });

    test('decodes the Map the driver returns for jsonb columns', () {
      expect(type.decode({'a': 1}), {'a': 1});
    });

    test('decodes a raw JSON string', () {
      expect(type.decode('{"a":1,"b":[2,3]}'), {
        'a': 1,
        'b': [2, 3],
      });
    });

    test('round-trips through its own encoding', () {
      final value = {
        'nested': {'k': 'v'},
        'list': [1, 2],
        'null': null,
      };
      expect(type.decode(type.encode(value)), value);
    });

    test('rejects non-JSON-object input', () {
      expect(() => type.decode(42), throwsArgumentError);
    });

    test('NullableSqlType wrapping gives the nullable variant for free', () {
      const nullable = NullableSqlType(PostgresJsonbSqlType());
      expect(nullable.encode(null), isNull);
      expect(nullable.decode(null), isNull);
      expect(nullable.decode({'a': 1}), {'a': 1});
    });
  });
}
