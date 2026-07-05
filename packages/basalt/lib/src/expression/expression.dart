import '../ast/sql_node.dart';

/// A typed SQL expression.
///
/// `T` is the SQL result type (e.g. `bool` for a predicate), and `Tbl` is the
/// phantom table-scope marker. The `Tbl` parameter is what prevents mixing
/// columns from unrelated tables in a single `WHERE` clause at compile time —
/// the Dart analog of Basalt's `AppearsInFromClause`.
class Expression<T, Tbl> {
  final SqlNode node;
  const Expression(this.node);
}

/// Boolean combinators are only meaningful on predicates, so they live on an
/// extension over `Expression<bool, Tbl>` rather than the general class.
extension BoolExpression<Tbl> on Expression<bool, Tbl> {
  Expression<bool, Tbl> and(Expression<bool, Tbl> other) =>
      Expression(BinaryNode(node, 'AND', other.node));

  Expression<bool, Tbl> or(Expression<bool, Tbl> other) =>
      Expression(BinaryNode(node, 'OR', other.node));

  Expression<bool, Tbl> operator &(Expression<bool, Tbl> other) => and(other);
  Expression<bool, Tbl> operator |(Expression<bool, Tbl> other) => or(other);
}
