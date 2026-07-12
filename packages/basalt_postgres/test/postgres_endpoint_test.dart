import 'package:basalt_postgres/adapter.dart';
import 'package:test/test.dart';

void main() {
  group('PostgresEndpoint.fromOptions with url', () {
    test('parses credentials, host, port, database and sslmode', () {
      final endpoint = PostgresEndpoint.fromOptions({
        'url': 'postgres://user:p%40ss@db.example.com:6432/shop'
            '?sslmode=disable',
      });
      expect(endpoint.host, 'db.example.com');
      expect(endpoint.port, 6432);
      expect(endpoint.database, 'shop');
      expect(endpoint.username, 'user');
      expect(endpoint.password, 'p@ss');
      expect(endpoint.ssl, isFalse);
    });

    test('applies defaults for omitted parts', () {
      final endpoint =
          PostgresEndpoint.fromOptions({'url': 'postgresql://localhost/app'});
      expect(endpoint.host, 'localhost');
      expect(endpoint.port, 5432);
      expect(endpoint.username, 'postgres');
      expect(endpoint.password, '');
      expect(endpoint.ssl, isTrue);
    });

    test('rejects a URL without a database name', () {
      expect(
        () => PostgresEndpoint.fromOptions({'url': 'postgres://localhost'}),
        throwsArgumentError,
      );
    });

    test('rejects a non-postgres scheme', () {
      expect(
        () => PostgresEndpoint.fromOptions({'url': 'mysql://localhost/app'}),
        throwsArgumentError,
      );
    });

    test('rejects url combined with manual keys', () {
      expect(
        () => PostgresEndpoint.fromOptions({
          'url': 'postgres://localhost/app',
          'host': 'elsewhere',
        }),
        throwsArgumentError,
      );
    });
  });

  group('PostgresEndpoint.fromOptions with manual keys', () {
    test('applies defaults around the required database', () {
      final endpoint = PostgresEndpoint.fromOptions({'database': 'shop'});
      expect(endpoint.host, 'localhost');
      expect(endpoint.port, 5432);
      expect(endpoint.database, 'shop');
      expect(endpoint.username, 'postgres');
      expect(endpoint.password, '');
      expect(endpoint.ssl, isTrue);
    });

    test('reads every key', () {
      final endpoint = PostgresEndpoint.fromOptions({
        'host': 'db.internal',
        'port': 6432,
        'database': 'shop',
        'username': 'svc',
        'password': 'secret',
        'ssl': false,
      });
      expect(endpoint.host, 'db.internal');
      expect(endpoint.port, 6432);
      expect(endpoint.username, 'svc');
      expect(endpoint.password, 'secret');
      expect(endpoint.ssl, isFalse);
    });

    test('missing database throws', () {
      expect(
        () => PostgresEndpoint.fromOptions({'host': 'localhost'}),
        throwsA(
          isArgumentError.having(
            (e) => e.message,
            'message',
            contains('postgres adapter'),
          ),
        ),
      );
    });

    test('unknown key throws', () {
      expect(
        () => PostgresEndpoint.fromOptions({'database': 'x', 'path': 'x.db'}),
        throwsArgumentError,
      );
    });

    test('wrong value types throw', () {
      expect(
        () => PostgresEndpoint.fromOptions({'database': 'x', 'port': '5432'}),
        throwsArgumentError,
      );
      expect(
        () => PostgresEndpoint.fromOptions({'database': 'x', 'ssl': 'no'}),
        throwsArgumentError,
      );
    });
  });
}
