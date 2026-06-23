import 'package:diesel/diesel.dart';

/// The migrations bookkeeping table (mirrors Diesel's `__diesel_schema_migrations`).
/// Defined with the query builder so the CLI dogfoods the ORM itself.
abstract final class SchemaMigrationsTable {
  static const _t = '__diesel_schema_migrations';
  static const version =
      ValueColumn<String, SchemaMigrationsTable>(_t, 'version', SqlType.text);
  static const runOn =
      ValueColumn<String, SchemaMigrationsTable>(_t, 'run_on', SqlType.text);
  static const table =
      TableRef<SchemaMigrationsTable>(_t, [version, runOn]);
}
