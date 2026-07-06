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
        BinaryNode(selectExpression, op, ParamNode(type.encode(value))),
      );
}

/// `COUNT(*)` — total row count.
Aggregate<int> countAll() =>
    const Aggregate('COUNT', null, 'count', IntSqlType());

/// Resolves a numeric aggregate operand: its AST node, its decode type, and
/// (for columns) the SQL column name used to derive a default alias.
(SqlNode, SqlType<Object?>, String?) _numericOperand(Object operand) =>
    switch (operand) {
      final TableColumn<int, Object?> c => (
          c.node,
          const IntOrNullSqlType(),
          c.name
        ),
      final TableColumn<double, Object?> c => (
          c.node,
          const DoubleOrNullSqlType(),
          c.name
        ),
      final Expression<num, Object?> e => (
          e.node,
          const DoubleOrNullSqlType(),
          null
        ),
      _ => throw ArgumentError.value(
          operand,
          'operand',
          'Must be a numeric column or expression',
        ),
    };

/// Picks the aggregate's alias: explicit [as] wins, else `sum_$column` style
/// derived from the column name; expression operands must alias explicitly.
String _aggregateAlias(String function, String? as, String? columnName) {
  if (as case final alias?) return alias;
  if (columnName case final name?) return '${function.toLowerCase()}_$name';
  throw ArgumentError(
    "$function over an expression needs an explicit alias — pass as: 'name'.",
  );
}

/// Builds `SUM`/`MIN`/`MAX` with a decode type checked against the operand.
Aggregate<T?> _numericAggregate<T extends num>(
  String function,
  Object operand,
  String? as,
) {
  final (node, type, columnName) = _numericOperand(operand);
  if (type is! SqlType<T?>) {
    throw ArgumentError(
      '$function<$T> does not match the operand: integer columns decode to '
      '$function<int>, double columns and expressions to $function<double>.',
    );
  }
  return Aggregate(
    function,
    node,
    _aggregateAlias(function, as, columnName),
    type,
  );
}

/// `SUM` over a numeric column or expression.
///
/// Integer columns decode to `Aggregate<int?>`; double columns and arbitrary
/// expressions decode to `Aggregate<double?>` (nullable: SQL returns NULL
/// over an empty set). When [as] is omitted the alias is derived from the
/// column name (`sum_age`); expression operands require an explicit [as].
Aggregate<T?> sum<T extends num>(Object operand, {String? as}) =>
    _numericAggregate('SUM', operand, as);

/// `MIN` over a numeric column or expression — typed like [sum]
/// (integer columns decode to `Aggregate<int?>`).
Aggregate<T?> min<T extends num>(Object operand, {String? as}) =>
    _numericAggregate('MIN', operand, as);

/// `MAX` over a numeric column or expression — typed like [sum]
/// (integer columns decode to `Aggregate<int?>`).
Aggregate<T?> max<T extends num>(Object operand, {String? as}) =>
    _numericAggregate('MAX', operand, as);

/// `AVG` over a numeric column or expression — always decodes to
/// `Aggregate<double?>`. Alias defaults to `avg_$column` for columns.
Aggregate<double?> avg(Object operand, {String? as}) {
  final (node, _, columnName) = _numericOperand(operand);
  return Aggregate(
    'AVG',
    node,
    _aggregateAlias('AVG', as, columnName),
    const DoubleOrNullSqlType(),
  );
}

/// `COUNT(DISTINCT col)`. Alias defaults to `count_$column`.
Aggregate<int> countDistinct(
  TableColumn<Object?, Object?> column, {
  String? as,
}) =>
    Aggregate(
      'COUNT',
      column.node,
      as ?? 'count_${column.name}',
      const IntSqlType(),
      distinct: true,
    );
