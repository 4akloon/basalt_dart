import 'package:basalt/basalt.dart';

import '../dto/column_filter.dart';
import '../dto/registered_instance.dart';
import '../dto/schema_dto.dart';
import '../dto/sql_result_dto.dart';
import '../dto/table_page_dto.dart';
import 'basalt_dev_tools.dart';
import 'inspector_exception.dart';
import 'row_updater.dart';
import 'schema_reader.dart';
import 'sql_runner.dart';
import 'table_reader.dart';

/// Backend-agnostic facade behind the `ext.basalt.*` service extensions.
///
/// Resolves an instance id to its live [Connection] and delegates each
/// operation to a focused collaborator ([SchemaReader], [TableReader],
/// [RowUpdater], [SqlRunner]). Because it works purely through the [Connection]
/// interface and the [BasaltDevTools] registry, it is directly unit-testable
/// without a VM service round-trip.
final class InspectorService {
  /// Creates the shared inspector facade.
  const InspectorService();

  /// The instances currently registered for inspection.
  Future<List<RegisteredInstance>> listInstances() async =>
      BasaltDevTools.instances;

  /// Introspects [id]'s schema into a transport-friendly model.
  Future<SchemaDto> getSchema(String id) =>
      SchemaReader(_connection(id)).read();

  /// Reads one page of rows from [table] on instance [id].
  Future<TablePageDto> getTableData(
    String id, {
    required String table,
    int limit = 50,
    int offset = 0,
    String? orderBy,
    bool desc = false,
    List<ColumnFilter> filters = const [],
  }) =>
      TableReader(_connection(id)).read(
        table: table,
        limit: limit,
        offset: offset,
        orderBy: orderBy,
        desc: desc,
        filters: filters,
      );

  /// Updates a single row of [table] on instance [id]: `changes` where `key`.
  Future<void> updateRow(
    String id, {
    required String table,
    required Map<String, Object?> key,
    required Map<String, Object?> changes,
  }) =>
      RowUpdater(_connection(id)).update(
        table: table,
        key: key,
        changes: changes,
      );

  /// Runs an arbitrary SQL statement (dev-only; reads *and* writes) on [id].
  Future<SqlResultDto> runSql(
    String id,
    String sql, [
    List<Object?> params = const [],
  ]) =>
      SqlRunner(_connection(id)).run(sql, params);

  Connection _connection(String id) {
    final conn = BasaltDevTools.connection(id);
    if (conn == null) throw InspectorException('Unknown instance: $id');
    return conn;
  }
}
