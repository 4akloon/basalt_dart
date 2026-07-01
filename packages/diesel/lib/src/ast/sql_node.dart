/// Untyped SQL expression tree.
///
/// The typed query-builder API ([Expression], [TableColumn]) produces these nodes,
/// and the serializer walks them to emit `(sql, params)`. Keeping the AST
/// untyped here lets the serializer stay simple and dialect-agnostic; all type
/// information lives in the builder layer above.
library;

/// A single node in a SQL expression tree.
sealed class SqlNode {
  const SqlNode();
}

/// Reference to a table column, e.g. `"users"."age"`.
final class ColumnNode extends SqlNode {
  final String table;
  final String name;
  const ColumnNode(this.table, this.name);
}

/// A bound parameter. [value] is already encoded to a driver-ready value
/// (see [SqlType.encode]); the serializer only emits a placeholder for it.
final class ParamNode extends SqlNode {
  final Object? value;
  const ParamNode(this.value);
}

/// Binary infix operation: `left <op> right` (e.g. `=`, `>`, `AND`, `LIKE`).
final class BinaryNode extends SqlNode {
  final SqlNode left;
  final String op;
  final SqlNode right;
  const BinaryNode(this.left, this.op, this.right);
}

/// `target IN (v1, v2, ...)`. [values] are already encoded.
final class InNode extends SqlNode {
  final SqlNode target;
  final List<Object?> values;
  const InNode(this.target, this.values);
}

/// `target IS NULL` / `target IS NOT NULL`.
final class NullCheckNode extends SqlNode {
  final SqlNode target;
  final bool negated;
  const NullCheckNode(this.target, {this.negated = false});
}

/// `target BETWEEN low AND high`. [low]/[high] are already encoded.
final class BetweenNode extends SqlNode {
  final SqlNode target;
  final Object? low;
  final Object? high;
  const BetweenNode(this.target, this.low, this.high);
}

/// A function call, e.g. `COUNT(*)` or `SUM("users"."age")`. [argument] is null
/// for `COUNT(*)`.
final class FunctionNode extends SqlNode {
  final String name;
  final SqlNode? argument;
  const FunctionNode(this.name, this.argument);
}

/// One `ORDER BY` term.
final class Ordering {
  final ColumnNode column;
  final bool ascending;
  const Ordering(this.column, {this.ascending = true});
}

/// One item in a SELECT projection: an [expression] plus an optional `AS` [alias].
/// Built from a `Selection` so the serializer stays purely AST-level.
final class Projection {
  final SqlNode expression;
  final String? alias;
  const Projection(this.expression, {this.alias});
}

enum JoinKind { inner, left }

/// A single `JOIN <table> [AS <alias>] ON <condition>` in a query's FROM clause.
/// [alias] is set when the same table is joined more than once (self-joins).
final class Join {
  final JoinKind kind;
  final String table;
  final String? alias;
  final SqlNode on;
  const Join(this.kind, this.table, this.on, {this.alias});
}
