import 'package:basalt/basalt.dart';

/// The migrations bookkeeping table (tracks applied `__basalt_schema_migrations`).
/// Defined with the query builder so the migration engine dogfoods the ORM.
abstract final class SchemaMigrationsTable {
  static const _t = '__basalt_schema_migrations';
  static const version = ValueColumn<String, SchemaMigrationsTable>(
    _t,
    'version',
    StringSqlType(),
  );
  static const runOn =
      ValueColumn<String, SchemaMigrationsTable>(_t, 'run_on', StringSqlType());
  static const table = TableRef<SchemaMigrationsTable>(_t, [version, runOn]);
}
