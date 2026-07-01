import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../types/sql_type.dart';

/// Something selectable in a query's projection — a [TableColumn] or an
/// [Aggregate]. Carries the SQL [selectExpression] to emit, an optional `AS`
/// [selectAlias], the [readKey] a `RowReader` uses to find the value, and the
/// [SqlType] used to decode it.
abstract interface class Selection<T> {
  SqlType<T> get type;
  SqlNode get selectExpression;
  String? get selectAlias;
  String get readKey;
}

/// A typed column belonging to table `Tbl`.
///
/// Sealed: every column is exactly one of [ValueColumn], [PrimaryKey] or [Ref]
/// (a foreign key). This lets the join API and codegen pattern-match on the
/// column kind and gives FK-aware joins.
///
/// Columns are declared `static const` on a table marker class so the same
/// object serves the query builder (`Users.age.gt(18)`) and derive annotations
/// (`@Column(Users.name)`) — annotation arguments must be constants. A column is
/// also a [Selection], so it can be read straight out of a row.
sealed class TableColumn<T, Tbl> implements Selection<T> {
  const TableColumn();

  String get table;
  String get name;
  @override
  SqlType<T> get type;

  ColumnNode get node => ColumnNode(table, name);

  @override
  SqlNode get selectExpression => node;
  @override
  String? get selectAlias => null;
  @override
  String get readKey => '$table.$name';

  Expression<bool, Tbl> eq(T value) => _cmp('=', value);
  Expression<bool, Tbl> ne(T value) => _cmp('<>', value);
  Expression<bool, Tbl> gt(T value) => _cmp('>', value);
  Expression<bool, Tbl> ge(T value) => _cmp('>=', value);
  Expression<bool, Tbl> lt(T value) => _cmp('<', value);
  Expression<bool, Tbl> le(T value) => _cmp('<=', value);

  // Operator sugar. `==` is intentionally left alone (identity/hashing); use
  // `eq` for SQL equality.
  Expression<bool, Tbl> operator >(T value) => gt(value);
  Expression<bool, Tbl> operator <(T value) => lt(value);
  Expression<bool, Tbl> operator >=(T value) => ge(value);
  Expression<bool, Tbl> operator <=(T value) => le(value);

  Expression<bool, Tbl> isIn(List<T> values) =>
      Expression(InNode(node, values.map(type.encode).toList()));

  /// diesel-style alias for [isIn] (`eq_any`).
  Expression<bool, Tbl> eqAny(List<T> values) => isIn(values);

  /// `COUNT(this_column)` — a non-null count, selectable and readable.
  Aggregate<int> count() =>
      Aggregate('COUNT', node, 'count_$name', SqlType.integer);

  Expression<bool, Tbl> between(T low, T high) =>
      Expression(BetweenNode(node, type.encode(low), type.encode(high)));

  Expression<bool, Tbl> isNull() => Expression(NullCheckNode(node));
  Expression<bool, Tbl> isNotNull() =>
      Expression(NullCheckNode(node, negated: true));

  /// Compares this column to another column — for JOIN `ON` clauses and
  /// cross-table predicates. The shared `T` enforces matching key types
  /// (`Users.id.eqColumn(Posts.title)` is a compile error).
  Expression<bool, Tbl> eqColumn<Other>(TableColumn<T, Other> other) =>
      Expression(BinaryNode(node, '=', other.node));

  /// Produces a typed assignment for INSERT/UPDATE, e.g. `Users.age.set(31)`.
  /// The value type is pinned by this column's static type (no inference), so
  /// `TableColumn<int>.set('x')` is a compile error.
  ColumnValue<Tbl> set(T value) => ColumnValue(name, type.encode(value));

  Ordering asc() => Ordering(node, ascending: true);
  Ordering desc() => Ordering(node, ascending: false);

  Expression<bool, Tbl> _cmp(String op, T value) =>
      Expression(BinaryNode(node, op, ParamNode(type.encode(value))));
}

/// An ordinary value column.
final class ValueColumn<T, Tbl> extends TableColumn<T, Tbl> {
  @override
  final String table;
  @override
  final String name;
  @override
  final SqlType<T> type;
  const ValueColumn(this.table, this.name, this.type);
}

/// A primary-key column.
final class PrimaryKey<T, Tbl> extends TableColumn<T, Tbl> {
  @override
  final String table;
  @override
  final String name;
  @override
  final SqlType<T> type;
  const PrimaryKey(this.table, this.name, this.type);
}

/// A foreign-key column on `Tbl` that references the [PrimaryKey] of `Target`.
/// Referencing the PK column object (a leaf) keeps it const-cycle free even for
/// mutual foreign keys, and the shared `T` enforces matching key types.
final class Ref<T, Tbl, Target> extends TableColumn<T, Tbl> {
  @override
  final String table;
  @override
  final String name;
  @override
  final SqlType<T> type;
  final PrimaryKey<T, Target> references;
  const Ref(this.table, this.name, this.type, {required this.references});
}

/// `LIKE` only makes sense for text columns.
extension TextColumn<Tbl> on TableColumn<String, Tbl> {
  Expression<bool, Tbl> like(String pattern) =>
      Expression(BinaryNode(node, 'LIKE', ParamNode(pattern)));
}

/// An aggregate over a column (or `COUNT(*)`), usable in `select(...)` and
/// readable from a row via its [readKey]. Build with [TableColumn.count],
/// [countAll], or the numeric aggregates ([IntColumnAggregates]).
final class Aggregate<T> implements Selection<T> {
  final String function;
  final SqlNode? _argument;
  final String _alias;
  @override
  final SqlType<T> type;
  const Aggregate(this.function, this._argument, this._alias, this.type);

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

  Expression<bool, Object?> _cmp(String op, T value) =>
      Expression(BinaryNode(selectExpression, op, ParamNode(type.encode(value))));
}

/// `COUNT(*)` — total row count.
Aggregate<int> countAll() =>
    const Aggregate('COUNT', null, 'count', SqlType.integer);

/// Numeric aggregates for integer columns. SQLite returns NULL over an empty
/// set, so these decode to nullable Dart types.
extension IntColumnAggregates<Tbl> on TableColumn<int, Tbl> {
  Aggregate<int?> sum() =>
      Aggregate('SUM', node, 'sum_$name', SqlType.integerOrNull);
  Aggregate<double?> avg() =>
      Aggregate('AVG', node, 'avg_$name', SqlType.realOrNull);
  Aggregate<int?> min() =>
      Aggregate('MIN', node, 'min_$name', SqlType.integerOrNull);
  Aggregate<int?> max() =>
      Aggregate('MAX', node, 'max_$name', SqlType.integerOrNull);
}

/// A column-scoped assignment (`column = value`) for INSERT/UPDATE. The value is
/// already encoded; `Tbl` keeps it bound to its table.
final class ColumnValue<Tbl> {
  final String column;
  final Object? encoded;
  const ColumnValue(this.column, this.encoded);
}

/// Something a query can read FROM or JOIN: a real table ([TableRef]) or an
/// aliased one ([TableAlias]). `columns` are bound to the source's effective
/// name (`alias ?? table`), so reads/predicates address the right instance.
abstract interface class QuerySource<Tbl> {
  String get table; // real table name (FROM/JOIN target)
  String? get alias; // alias, or null
  List<TableColumn<Object?, Object?>> get columns;

  /// Rebinds a base-table column to this source's effective name (identity on
  /// [TableRef], alias-bound on [TableAlias]).
  TableColumn<T, Tbl> col<T>(TableColumn<T, Tbl> column);
}

/// Table descriptor: its name and full column list (the default projection for
/// `from`/joins). Cycle-safe even with foreign keys because [Ref] points at a
/// [PrimaryKey] leaf, not back at a `TableRef`.
final class TableRef<Tbl> implements QuerySource<Tbl> {
  final String name;
  @override
  final List<TableColumn<Object?, Object?>> columns;
  const TableRef(this.name, this.columns);

  @override
  String get table => name;
  @override
  String? get alias => null;

  @override
  TableColumn<T, Tbl> col<T>(TableColumn<T, Tbl> column) => column;

  /// Alias this table for a self-join — `Users.table.aliased('sender')`.
  TableAlias<Tbl> aliased(String alias) => TableAlias(alias, this);
}

/// An aliased table for self-joins (the same table joined more than once).
/// Columns are rebound to the alias, so `sender.col(Users.id)` serializes as
/// `"sender"."id"` and is distinct from `recipient.col(Users.id)`.
final class TableAlias<Tbl> implements QuerySource<Tbl> {
  @override
  final String alias;
  final TableRef<Tbl> base;
  const TableAlias(this.alias, this.base);

  @override
  String get table => base.name;

  @override
  List<TableColumn<Object?, Object?>> get columns => [
        for (final c in base.columns)
          ValueColumn<Object?, Tbl>(alias, c.name, c.type)
      ];

  /// An alias-bound version of one of the base table's columns.
  @override
  TableColumn<T, Tbl> col<T>(TableColumn<T, Tbl> column) =>
      ValueColumn<T, Tbl>(alias, column.name, column.type);
}
