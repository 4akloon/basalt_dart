import '../ast/sql_node.dart';
import '../query/query.dart';
import '../query/write.dart';
import '../types/sql_type.dart';
import 'sql_dialect.dart';

/// A serialized statement: the SQL text and its ordered bound parameters.
typedef CompiledQuery = (String sql, List<Object?> params);

/// Walks an untyped AST and emits `(sql, params)` for a given [SqlDialect].
///
/// Pure string/value transformation — it never touches a database driver,
/// which keeps serialization trivially unit-testable.
///
/// {@category serialization}
final class QueryBuilder {
  QueryBuilder(this.dialect);
  final SqlDialect dialect;
  final StringBuffer _sql = StringBuffer();
  final List<Object?> _params = [];

  CompiledQuery buildSelect(SelectQuery<dynamic> stmt) {
    _validateScope(stmt);
    _sql.write('SELECT ');
    if (stmt.isDistinct) _sql.write('DISTINCT ');
    var firstProjection = true;
    for (final p in stmt.projection) {
      if (!firstProjection) _sql.write(', ');
      firstProjection = false;
      _writeNode(p.expression);
      if (p.alias case final alias?) {
        _sql
          ..write(' AS ')
          ..write(dialect.quoteIdentifier(alias));
      }
    }
    _sql
      ..write(' FROM ')
      ..write(dialect.quoteIdentifier(stmt.fromTable));
    if (stmt.fromAlias case final alias?) {
      _sql
        ..write(' AS ')
        ..write(dialect.quoteIdentifier(alias));
    }
    for (final join in stmt.joins) {
      _sql
        ..write(
          switch (join.kind) {
            JoinKind.inner => ' INNER JOIN ',
            JoinKind.left => ' LEFT JOIN ',
          },
        )
        ..write(dialect.quoteIdentifier(join.table));
      if (join.alias case final alias?) {
        _sql
          ..write(' AS ')
          ..write(dialect.quoteIdentifier(alias));
      }
      _sql.write(' ON ');
      _writeNode(join.on);
    }
    if (stmt is FoldMappedQuery &&
        (stmt.parentLimit != null || stmt.parentOffset != null)) {
      _writeParentLimitedWhere(stmt);
    } else if (stmt.whereNode case final where?) {
      _sql.write(' WHERE ');
      _writeNode(where);
    }
    if (stmt.groupByColumns.isNotEmpty) {
      _sql.write(' GROUP BY ');
      _sql.write(stmt.groupByColumns.map(_column).join(', '));
    }
    if (stmt.havingNode case final having?) {
      _sql.write(' HAVING ');
      _writeNode(having);
    }
    if (stmt is! FoldMappedQuery && stmt.orderings.isNotEmpty) {
      _sql.write(' ORDER BY ');
      var first = true;
      for (final o in stmt.orderings) {
        if (!first) _sql.write(', ');
        first = false;
        _writeNode(o.expression);
        _sql.write(o.ascending ? ' ASC' : ' DESC');
      }
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

  void _writeParentLimitedWhere(FoldMappedQuery<dynamic> stmt) {
    final pk = stmt.rootPkColumn;
    if (pk == null) {
      throw StateError(
        'FoldMappedQuery.limit()/offset() requires withRootPk(pk) before load.',
      );
    }
    final pkNode = pk.node;
    _sql.write(' WHERE ');
    _writeNode(pkNode);
    _sql.write(' IN (SELECT ');
    _writeNode(pkNode);
    _sql
      ..write(' FROM ')
      ..write(dialect.quoteIdentifier(stmt.fromTable));
    if (stmt.fromAlias case final alias?) {
      _sql
        ..write(' AS ')
        ..write(dialect.quoteIdentifier(alias));
    }
    if (stmt.whereNode case final where?) {
      _sql.write(' WHERE ');
      _writeNode(where);
    }
    if (stmt.orderings.isNotEmpty) {
      _sql.write(' ORDER BY ');
      var first = true;
      for (final o in stmt.orderings) {
        if (!first) _sql.write(', ');
        first = false;
        _writeNode(o.expression);
        _sql.write(o.ascending ? ' ASC' : ' DESC');
      }
    }
    if (stmt.parentLimit case final limit?) {
      _sql
        ..write(' LIMIT ')
        ..write(_bind(limit));
    }
    if (stmt.parentOffset case final offset?) {
      _sql
        ..write(' OFFSET ')
        ..write(_bind(offset));
    }
    _sql.write(')');
  }

  /// Verifies every referenced column belongs to a table in the FROM/JOIN
  /// clause — the runtime safety net for joined queries (single-table queries
  /// are already guaranteed by the type system). Also rejects `HAVING` without
  /// `GROUP BY`: SQLite errors on it (standard SQL/Postgres would treat the
  /// whole table as one group) — strictness matches the SQLite-first posture.
  void _validateScope(SelectQuery<dynamic> stmt) {
    if (stmt.havingNode != null && stmt.groupByColumns.isEmpty) {
      throw StateError(
        'having() requires groupBy() — HAVING without GROUP BY is not supported.',
      );
    }
    // Columns address a source by its effective name (alias when aliased).
    final allowed = {
      stmt.fromAlias ?? stmt.fromTable,
      for (final j in stmt.joins) j.alias ?? j.table,
    };
    for (final p in stmt.projection) {
      _checkNode(p.expression, allowed);
    }
    for (final ordering in stmt.orderings) {
      _checkNode(ordering.expression, allowed);
    }
    for (final column in stmt.groupByColumns) {
      _checkColumn(column, allowed);
    }
    if (stmt.havingNode case final having?) {
      _checkNode(having, allowed);
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
      case FunctionNode(:final argument):
        if (argument != null) _checkNode(argument, allowed);
      case RawNode():
        break;
    }
  }

  /// Serializes a write, optionally appending a `RETURNING` clause (its columns
  /// are referenced unqualified, as SQLite requires).
  CompiledQuery buildWrite(
    WriteStatement stmt, {
    List<Projection> returning = const [],
  }) {
    switch (stmt) {
      case InsertStatement():
        _writeInsert(stmt);
      case UpdateStatement():
        _writeUpdate(stmt);
      case UpdateAllStatement():
        _writeUpdateAll(stmt);
      case DeleteStatement():
        _writeDelete(stmt);
    }
    if (returning.isNotEmpty) {
      // updateAll's VALUES table shares its column names with the target, so
      // its RETURNING columns must be table-qualified to stay unambiguous;
      // everywhere else they are unqualified, as SQLite requires.
      final qualify = stmt is UpdateAllStatement;
      _sql.write(' RETURNING ');
      var first = true;
      for (final p in returning) {
        if (!first) _sql.write(', ');
        first = false;
        final expr = p.expression;
        if (expr is ColumnNode) {
          _sql.write(
            qualify ? _column(expr) : dialect.quoteIdentifier(expr.name),
          );
        } else {
          _writeNode(expr);
        }
        if (p.alias case final alias?) {
          _sql
            ..write(' AS ')
            ..write(dialect.quoteIdentifier(alias));
        }
      }
    }
    return _result();
  }

  void _writeInsert(InsertStatement stmt) {
    if (stmt.rows.isEmpty) {
      throw StateError(
        'INSERT into "${stmt.table}" has no rows — add .value(...) or '
        '.values(...) with at least one row.',
      );
    }
    final cols = stmt.columns.map(dialect.quoteIdentifier).join(', ');
    final tuples = [
      for (final row in stmt.rows) '(${row.map(_bind).join(', ')})',
    ].join(', ');
    _sql.write(
      'INSERT INTO ${dialect.quoteIdentifier(stmt.table)} ($cols) VALUES $tuples',
    );
    if (stmt.conflictTarget case final target?) {
      _sql.write(' ON CONFLICT');
      if (target.isNotEmpty) {
        _sql.write(' (${target.map(dialect.quoteIdentifier).join(', ')})');
      }
      if (stmt.conflictDoNothing) {
        _sql.write(' DO NOTHING');
      } else {
        _sql.write(' DO UPDATE SET ');
        var first = true;
        for (final a in stmt.conflictSet) {
          if (!first) _sql.write(', ');
          first = false;
          _sql
            ..write(dialect.quoteIdentifier(a.column))
            ..write(' = ');
          if (a.isExcluded) {
            _sql.write('excluded.${dialect.quoteIdentifier(a.column)}');
          } else {
            _sql.write(_bind(a.encoded));
          }
        }
      }
    }
  }

  void _writeUpdate(UpdateStatement stmt) {
    _sql.write('UPDATE ${dialect.quoteIdentifier(stmt.table)} SET ');
    var first = true;
    for (final a in stmt.assignments) {
      if (a.isExcluded) {
        throw StateError('setToExcluded is only valid in upsert ON CONFLICT');
      }
      if (!first) _sql.write(', ');
      first = false;
      _sql
        ..write(dialect.quoteIdentifier(a.column))
        ..write(' = ');
      if (a.valueExpr case final expr?) {
        _writeNode(expr);
      } else {
        _sql.write(_bind(a.encoded));
      }
    }
    if (stmt.whereNode case final where?) {
      _sql.write(' WHERE ');
      _writeNode(where);
    }
  }

  /// The CTE alias the batch update joins against; prefixed so it can't
  /// plausibly collide with a user table name.
  static const _valuesAlias = '__basalt_values';

  /// `WITH v(cols) AS (VALUES ...) UPDATE t SET c = v.c FROM v WHERE t.k = v.k`.
  ///
  /// The CTE form (rather than `(VALUES ...) AS v(cols)`) is what SQLite can
  /// name columns on; Postgres runs it unchanged. First-row values are wrapped
  /// in ANSI `CAST(...)` when the dialect asks for one — a bare-`VALUES` table
  /// gives Postgres no context to infer parameter types, and the first row is
  /// enough because column type resolution propagates to the other rows.
  void _writeUpdateAll(UpdateAllStatement stmt) {
    if (stmt.rows.isEmpty) {
      throw StateError(
        'updateAll on "${stmt.table}" has no rows — add .values(...) with at '
        'least one row.',
      );
    }
    if (stmt.keyColumns.isEmpty) {
      throw StateError(
        'updateAll on "${stmt.table}" has no key — call .keyedBy(column) so '
        'the VALUES rows can be matched to table rows.',
      );
    }
    for (final key in stmt.keyColumns) {
      if (!stmt.columns.contains(key)) {
        throw StateError(
          'updateAll on "${stmt.table}": key column "$key" is missing from '
          'the rows — every row must set it.',
        );
      }
    }
    final setColumns = [
      for (final c in stmt.columns)
        if (!stmt.keyColumns.contains(c)) c,
    ];
    if (setColumns.isEmpty) {
      throw StateError(
        'updateAll on "${stmt.table}" sets only key columns — add at least '
        'one non-key column to update.',
      );
    }

    final alias = dialect.quoteIdentifier(_valuesAlias);
    final table = dialect.quoteIdentifier(stmt.table);
    final cols = stmt.columns.map(dialect.quoteIdentifier).join(', ');
    final tuples = [
      for (final (rowIndex, row) in stmt.rows.indexed)
        '(${[
          for (final (colIndex, value) in row.indexed)
            _bindCast(value, rowIndex == 0 ? stmt.columnTypes[colIndex] : null),
        ].join(', ')})',
    ].join(', ');
    _sql.write('WITH $alias($cols) AS (VALUES $tuples) UPDATE $table SET ');
    _sql.write([
      for (final c in setColumns)
        '${dialect.quoteIdentifier(c)} = $alias.${dialect.quoteIdentifier(c)}',
    ].join(', '));
    _sql.write(' FROM $alias WHERE ');
    _sql.write([
      for (final k in stmt.keyColumns.map(dialect.quoteIdentifier))
        '$table.$k = $alias.$k',
    ].join(' AND '));
    if (stmt.whereNode case final where?) {
      _sql.write(' AND ');
      _writeNode(where);
    }
  }

  /// [_bind], wrapped in `CAST(... AS castType)` when the dialect maps [type]
  /// to a native type name.
  String _bindCast(Object? value, SqlType<Object?>? type) {
    final placeholder = _bind(value);
    if (type == null) return placeholder;
    if (dialect.castType(type) case final cast?) {
      return 'CAST($placeholder AS $cast)';
    }
    return placeholder;
  }

  void _writeDelete(DeleteStatement stmt) {
    _sql.write('DELETE FROM ${dialect.quoteIdentifier(stmt.table)}');
    if (stmt.whereNode case final where?) {
      _sql.write(' WHERE ');
      _writeNode(where);
    }
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
      case FunctionNode(:final name, :final argument, :final distinct):
        _sql
          ..write(name)
          ..write('(');
        if (distinct) _sql.write('DISTINCT ');
        if (argument == null) {
          _sql.write('*');
        } else {
          _writeNode(argument);
        }
        _sql.write(')');
      case RawNode(:final sql, :final params):
        _sql.write(sql);
        _params.addAll(params);
    }
  }

  String _column(ColumnNode c) =>
      '${dialect.quoteIdentifier(c.table)}.${dialect.quoteIdentifier(c.name)}';

  /// Registers a bound parameter and returns its placeholder.
  String _bind(Object? value) {
    final placeholder = dialect.placeholder(_params.length);
    _params.add(dialect.encodeParam(value));
    return placeholder;
  }

  CompiledQuery _result() => (_sql.toString(), _params);
}
