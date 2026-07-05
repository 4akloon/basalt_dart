part of 'table.dart';

/// An aggregate over a column (or `COUNT(*)`), usable in `select(...)` and
/// readable from a row via its [readKey]. Build with [TableColumn.count],
/// [countAll], or the numeric aggregates ([IntColumnAggregates]).
///
/// {@category schema}
final class Aggregate<T> implements Selection<T> {
  const Aggregate(
    this.function,
    this._argument,
    this._alias,
    this.type, {
    this.distinct = false,
  });
  final String function;
  final SqlNode? _argument;
  final String _alias;
  @override
  final SqlType<T> type;
  final bool distinct;

  @override
  SqlNode get selectExpression =>
      FunctionNode(function, _argument, distinct: distinct);
  @override
  String? get selectAlias => _alias;
  @override
  String get readKey => _alias;

  Ordering asc() => Ordering(selectExpression, ascending: true);
  Ordering desc() => Ordering(selectExpression, ascending: false);

  // Comparisons for `HAVING` (e.g. `Posts.views.sum().gt(100)`). Aggregates
  // aren't table-scoped, so these use the relaxed `Object?` scope.
  Expression<bool, Object?> eq(T value) => _cmp('=', value);
  Expression<bool, Object?> ne(T value) => _cmp('<>', value);
  Expression<bool, Object?> gt(T value) => _cmp('>', value);
  Expression<bool, Object?> ge(T value) => _cmp('>=', value);
  Expression<bool, Object?> lt(T value) => _cmp('<', value);
  Expression<bool, Object?> le(T value) => _cmp('<=', value);

  Expression<bool, Object?> _cmp(String op, T value) => Expression(
      BinaryNode(selectExpression, op, ParamNode(type.encode(value))),);
}

/// `COUNT(*)` — total row count.
Aggregate<int> countAll() =>
    const Aggregate('COUNT', null, 'count', SqlType.integer);

/// `SUM` over a numeric column or expression.
///
/// Integer columns decode to [Aggregate<int?>]; double columns and arbitrary
/// expressions decode to [Aggregate<double?>].
Aggregate<T?> sum<T extends num>(
  Object operand, {
  required String as,
}) {
  final (node, sqlType) = switch (operand) {
    TableColumn<int, Object?> c => (c.node, SqlType.integerOrNull),
    TableColumn<double, Object?> c => (c.node, SqlType.realOrNull),
    Expression<num, Object?> e => (e.node, SqlType.realOrNull),
    _ => throw ArgumentError.value(
        operand,
        'operand',
        'Must be a numeric column or expression',
      ),
  };
  return Aggregate('SUM', node, as, sqlType as SqlType<T?>);
}

/// `AVG(expr)` over an arbitrary numeric expression.
Aggregate<double?> avg(
  Expression<num, Object?> expression, {
  required String as,
}) =>
    Aggregate('AVG', expression.node, as, SqlType.realOrNull);

/// `MIN(expr)` over an arbitrary numeric expression.
Aggregate<double?> min(
  Expression<num, Object?> expression, {
  required String as,
}) =>
    Aggregate('MIN', expression.node, as, SqlType.realOrNull);

/// `MAX(expr)` over an arbitrary numeric expression.
Aggregate<double?> max(
  Expression<num, Object?> expression, {
  required String as,
}) =>
    Aggregate('MAX', expression.node, as, SqlType.realOrNull);

/// `COUNT(DISTINCT col)`.
Aggregate<int> countDistinct(
  TableColumn<Object?, Object?> column, {
  required String as,
}) =>
    Aggregate('COUNT', column.node, as, SqlType.integer, distinct: true);
