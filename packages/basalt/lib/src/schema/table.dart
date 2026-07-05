/// Typed schema surface: columns, selectables, and query sources.
///
/// The sealed [TableColumn] hierarchy ([ValueColumn] / [PrimaryKey] / [Ref])
/// is split across `part` files under `columns/`; the other selectables and
/// query sources each live in their own `part` file in this directory. Parts
/// keep the whole thing one library so the sealed switch stays exhaustive and
/// library-private members ([OnConflict]-style constructors, `_cmp`, …) stay
/// shared.
library;

import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../types/sql_type.dart';

part 'aggregate.dart';
part 'column_value.dart';
part 'columns/double_column_aggregates.dart';
part 'columns/int_column_aggregates.dart';
part 'columns/primary_key.dart';
part 'columns/ref.dart';
part 'columns/text_column.dart';
part 'columns/value_column.dart';
part 'query_source.dart';
part 'raw_selection.dart';
part 'selection.dart';
part 'table_alias.dart';
part 'table_ref.dart';

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
///
/// {@category schema}
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

  /// basalt-style alias for [isIn] (`eq_any`).
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

  /// For upserts: `col = excluded."col"` inside `ON CONFLICT ... DO UPDATE`,
  /// i.e. take the value from the row that failed to insert.
  ColumnValue<Tbl> setToExcluded() => ColumnValue(name, null, isExcluded: true);

  Ordering asc() => Ordering(node, ascending: true);
  Ordering desc() => Ordering(node, ascending: false);

  Expression<bool, Tbl> _cmp(String op, T value) =>
      Expression(BinaryNode(node, op, ParamNode(type.encode(value))));
}
