import '../serialize/sql_dialect.dart';

/// DDL for the internal migration tracker table, quoted for [dialect].
String createSchemaMigrationsTableSql(SqlDialect dialect) {
  final table = dialect.quoteIdentifier('__basalt_schema_migrations');
  final version = dialect.quoteIdentifier('version');
  final runOn = dialect.quoteIdentifier('run_on');
  return 'CREATE TABLE IF NOT EXISTS $table '
      '($version VARCHAR(50) PRIMARY KEY NOT NULL, '
      '$runOn TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)';
}
