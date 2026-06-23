import '../ast/sql_node.dart';
import '../query/select.dart';
import '../query/write.dart';
import 'sql_dialect.dart';

/// A serialized statement: the SQL text and its ordered bound parameters.
typedef CompiledQuery = (String sql, List<Object?> params);

/// Walks an untyped AST and emits `(sql, params)` for a given [SqlDialect].
///
/// Pure string/value transformation — it never touches a database driver,
/// which keeps serialization trivially unit-testable.
final class QueryBuilder {
  final SqlDialect dialect;
  final StringBuffer _sql = StringBuffer();
  final List<Object?> _params = [];

  QueryBuilder(this.dialect);

  CompiledQuery buildSelect(SelectQuery<dynamic> stmt) {
    _validateScope(stmt);
    _sql.write('SELECT ');
    _sql.write(stmt.projection.map(_column).join(', '));
    _sql
      ..write(' FROM ')
      ..write(dialect.quoteIdentifier(stmt.fromTable));
    for (final join in stmt.joins) {
      _sql
        ..write(switch (join.kind) {
          JoinKind.inner => ' INNER JOIN ',
          JoinKind.left => ' LEFT JOIN ',
        })
        ..write(dialect.quoteIdentifier(join.table))
        ..write(' ON ');
      _writeNode(join.on);
    }
    if (stmt.whereNode case final where?) {
      _sql.write(' WHERE ');
      _writeNode(where);
    }
    if (stmt.orderings.isNotEmpty) {
      _sql.write(' ORDER BY ');
      _sql.write(stmt.orderings
          .map((o) => '${_column(o.column)} ${o.ascending ? 'ASC' : 'DESC'}')
          .join(', '));
    }
    if (stmt.limitCount case final limit?) {
      _sql
        ..write(' LIMIT ')
        ..write(_bind(limit));
    }
    if (stmt.offsetCount case final offset?) {
      _sql
        ..write(' OFFSET ')
        ..write(_bind(offset));
    }
    return _result();
  }

  /// Verifies every referenced column belongs to a table in the FROM/JOIN
  /// clause — the runtime safety net for joined queries (single-table queries
  /// are already guaranteed by the type system).
  void _validateScope(SelectQuery<dynamic> stmt) {
    final allowed = {stmt.fromTable, for (final j in stmt.joins) j.table};
    for (final column in stmt.projection) {
      _checkColumn(column, allowed);
    }
    for (final ordering in stmt.orderings) {
      _checkColumn(ordering.column, allowed);
    }
    for (final join in stmt.joins) {
      _checkNode(join.on, allowed);
    }
    if (stmt.whereNode case final where?) {
      _checkNode(where, allowed);
    }
  }

  void _checkColumn(ColumnNode column, Set<String> allowed) {
    if (!allowed.contains(column.table)) {
      throw StateError(
          'Column "${column.table}"."${column.name}" is not in the query\'s '
          'FROM/JOIN clause (tables in scope: ${allowed.join(', ')})');
    }
  }

  void _checkNode(SqlNode node, Set<String> allowed) {
    switch (node) {
      case ColumnNode():
        _checkColumn(node, allowed);
      case ParamNode():
        break;
      case BinaryNode(:final left, :final right):
        _checkNode(left, allowed);
        _checkNode(right, allowed);
      case InNode(:final target):
        _checkNode(target, allowed);
      case NullCheckNode(:final target):
        _checkNode(target, allowed);
      case BetweenNode(:final target):
        _checkNode(target, allowed);
    }
  }

  CompiledQuery buildWrite(WriteStatement stmt) => switch (stmt) {
        InsertStatement() => _buildInsert(stmt),
        UpdateStatement() => _buildUpdate(stmt),
        DeleteStatement() => _buildDelete(stmt),
      };

  CompiledQuery _buildInsert(InsertStatement stmt) {
    final cols = stmt.columns.map(dialect.quoteIdentifier).join(', ');
    final placeholders = stmt.values.map(_bind).join(', ');
    _sql.write(
        'INSERT INTO ${dialect.quoteIdentifier(stmt.table)} ($cols) VALUES ($placeholders)');
    return _result();
  }

  CompiledQuery _buildUpdate(UpdateStatement stmt) {
    final assignments = [
      for (var i = 0; i < stmt.assignColumns.length; i++)
        '${dialect.quoteIdentifier(stmt.assignColumns[i])} = ${_bind(stmt.assignValues[i])}',
    ].join(', ');
    _sql.write('UPDATE ${dialect.quoteIdentifier(stmt.table)} SET $assignments');
    if (stmt.whereNode case final where?) {
      _sql.write(' WHERE ');
      _writeNode(where);
    }
    return _result();
  }

  CompiledQuery _buildDelete(DeleteStatement stmt) {
    _sql.write('DELETE FROM ${dialect.quoteIdentifier(stmt.table)}');
    if (stmt.whereNode case final where?) {
      _sql.write(' WHERE ');
      _writeNode(where);
    }
    return _result();
  }

  void _writeNode(SqlNode node) {
    switch (node) {
      case ColumnNode():
        _sql.write(_column(node));
      case ParamNode(:final value):
        _sql.write(_bind(value));
      case BinaryNode(:final left, :final op, :final right):
        _sql.write('(');
        _writeNode(left);
        _sql.write(' $op ');
        _writeNode(right);
        _sql.write(')');
      case InNode(:final target, :final values):
        _writeNode(target);
        _sql
          ..write(' IN (')
          ..write(values.map(_bind).join(', '))
          ..write(')');
      case NullCheckNode(:final target, :final negated):
        _writeNode(target);
        _sql.write(negated ? ' IS NOT NULL' : ' IS NULL');
      case BetweenNode(:final target, :final low, :final high):
        _writeNode(target);
        _sql
          ..write(' BETWEEN ')
          ..write(_bind(low))
          ..write(' AND ')
          ..write(_bind(high));
    }
  }

  String _column(ColumnNode c) =>
      '${dialect.quoteIdentifier(c.table)}.${dialect.quoteIdentifier(c.name)}';

  /// Registers a bound parameter and returns its placeholder.
  String _bind(Object? value) {
    final placeholder = dialect.placeholder(_params.length);
    _params.add(value);
    return placeholder;
  }

  CompiledQuery _result() => (_sql.toString(), _params);
}
