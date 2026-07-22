import 'package:basalt/basalt.dart';

/// The migrations bookkeeping table (tracks applied `__basalt_schema_migrations`).
/// Defined with the query builder so the migration engine dogfoods the ORM.
final class SchemaMigrationsTable extends TableRef<SchemaMigrationsTable> {
  const SchemaMigrationsTable._() : super('__basalt_schema_migrations');

  static const table = SchemaMigrationsTable._();

  static const version = ValueColumn<String, SchemaMigrationsTable>(
    table,
    'version',
    StringSqlType(),
  );
  static const runOn = ValueColumn<String, SchemaMigrationsTable>(
    table,
    'run_on',
    StringSqlType(),
  );

  @override
  List<TableColumn<Object?, Object?>> get columns => const [version, runOn];
}
