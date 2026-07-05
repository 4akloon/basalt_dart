part of 'table.dart';

/// An aggregate over a column (or `COUNT(*)`), usable in `select(...)` and
/// readable from a row via its [readKey]. Build with [TableColumn.count],
/// [countAll], or the numeric aggregates ([IntColumnAggregates]).
final class Aggregate<T> implements Selection<T> {
  const Aggregate(this.function, this._argument, this._alias, this.type);
  final String function;
  final SqlNode? _argument;
  final String _alias;
  @override
  final SqlType<T> type;

  @override
  SqlNode get selectExpression => FunctionNode(function, _argument);
  @override
  String? get selectAlias => _alias;
  @override
  String get readKey => _alias;

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
