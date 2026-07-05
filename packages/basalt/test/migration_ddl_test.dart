import 'package:basalt/basalt.dart';
import 'package:basalt/migration.dart';
import 'package:test/test.dart';

void main() {
  test('createSchemaMigrationsTableSql quotes identifiers', () {
    const dialect = _QuoteDialect();
    expect(
      createSchemaMigrationsTableSql(dialect),
      'CREATE TABLE IF NOT EXISTS "__basalt_schema_migrations" '
      '("version" VARCHAR(50) PRIMARY KEY NOT NULL, '
      '"run_on" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)',
    );
  });
}

final class _QuoteDialect implements SqlDialect {
  const _QuoteDialect();
  @override
  String quoteIdentifier(String name) => '"$name"';
  @override
  String placeholder(int index) => '?';
  @override
  Object? encodeParam(Object? value) => value;
}
