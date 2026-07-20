import 'package:basalt/basalt.dart';

import '../dto/column_filter.dart';
import 'inspector_exception.dart';
import 'param_binder.dart';
import 'schema_lookup.dart';

/// Builds a parameterized `WHERE` clause from [ColumnFilter]s against one table.
///
/// Column identifiers are validated and quoted; filter *values* are bound as
/// parameters through the shared [ParamBinder]. Terms are combined with `AND`.
final class WhereClause {
  /// Creates a builder for [_table], binding values via [_binder].
  const WhereClause(this._table, this._binder);

  final IntrospectedTable _table;
  final ParamBinder _binder;

  static const _comparisons = {
    'eq': '=',
    'ne': '<>',
    'lt': '<',
    'le': '<=',
    'gt': '>',
    'ge': '>=',
  };

  /// The ` WHERE ...` fragment (with leading space) for [filters], or `''`.
  String build(List<ColumnFilter> filters) {
    if (filters.isEmpty) return '';
    final terms = [for (final f in filters) _term(f)];
    return ' WHERE ${terms.join(' AND ')}';
  }

  String _term(ColumnFilter f) {
    final col = _binder.dialect.quoteIdentifier(
      SchemaLookup.column(_table, f.column).name,
    );
    return switch (f.op) {
      'isNull' => '$col IS NULL',
      'isNotNull' => '$col IS NOT NULL',
      'like' => '$col LIKE ${_binder.bind('${f.value ?? ''}')}',
      _ => _comparison(col, f),
    };
  }

  String _comparison(String col, ColumnFilter f) {
    final op = _comparisons[f.op];
    if (op == null) throw InspectorException('Unknown operator: ${f.op}');
    return '$col $op ${_binder.bind(f.value)}';
  }
}
