import 'package:basalt/basalt.dart';

import 'inspector_exception.dart';
import 'param_binder.dart';
import 'schema_lookup.dart';

/// Updates a single row identified by its key columns via raw SQL.
final class RowUpdater {
  /// Creates an updater over [_conn].
  const RowUpdater(this._conn);

  final Connection _conn;

  /// Applies [changes] to the row(s) of [table] matched by [key].
  ///
  /// An empty [key] is rejected so a stray edit can't rewrite the whole table;
  /// an empty [changes] is a no-op. Column names are validated against the
  /// schema and quoted; values are bound as parameters.
  Future<void> update({
    required String table,
    required Map<String, Object?> key,
    required Map<String, Object?> changes,
  }) async {
    if (changes.isEmpty) return;
    if (key.isEmpty) {
      throw const InspectorException('No key columns to identify the row');
    }
    final target = await SchemaLookup(_conn).table(table);
    final binder = ParamBinder(_conn.dialect);
    final sets = _assignments(target, changes, binder);
    final conds = _assignments(target, key, binder);

    final sql = 'UPDATE ${_quote(table)} SET ${sets.join(', ')} '
        'WHERE ${conds.join(' AND ')}';
    await _conn.executeSql(sql, binder.params);
  }

  List<String> _assignments(
    IntrospectedTable target,
    Map<String, Object?> values,
    ParamBinder binder,
  ) =>
      [
        for (final e in values.entries)
          '${_quote(SchemaLookup.column(target, e.key).name)}'
              ' = ${binder.bind(e.value)}',
      ];

  String _quote(String identifier) => _conn.dialect.quoteIdentifier(identifier);
}
