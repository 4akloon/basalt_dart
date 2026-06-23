import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../types/sql_type.dart';

/// A typed column belonging to table `Tbl`.
///
/// Sealed: every column is exactly one of [ValueColumn], [PrimaryKey] or [Ref]
/// (a foreign key). This lets the join API and codegen pattern-match on the
/// column kind and gives FK-aware joins.
///
/// Columns are declared `static const` on a table marker class so the same
/// object serves the query builder (`Users.age.gt(18)`) and derive annotations
/// (`@MapColumn(Users.name)`) — annotation arguments must be constants.
sealed class Column<T, Tbl> {
  const Column();

  String get table;
  String get name;
  SqlType<T> get type;

  ColumnNode get node => ColumnNode(table, name);

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

  Expression<bool, Tbl> between(T low, T high) =>
      Expression(BetweenNode(node, type.encode(low), type.encode(high)));

  Expression<bool, Tbl> isNull() => Expression(NullCheckNode(node));
  Expression<bool, Tbl> isNotNull() =>
      Expression(NullCheckNode(node, negated: true));

  /// Compares this column to another column — for JOIN `ON` clauses and
  /// cross-table predicates. The shared `T` enforces matching key types
  /// (`Users.id.eqColumn(Posts.title)` is a compile error).
  Expression<bool, Tbl> eqColumn<Other>(Column<T, Other> other) =>
      Expression(BinaryNode(node, '=', other.node));

  /// Produces a typed assignment for INSERT/UPDATE, e.g. `Users.age.set(31)`.
  /// The value type is pinned by this column's static type (no inference), so
  /// `Column<int>.set('x')` is a compile error.
  ColumnValue<Tbl> set(T value) => ColumnValue(name, type.encode(value));

  Ordering asc() => Ordering(node, ascending: true);
  Ordering desc() => Ordering(node, ascending: false);

  Expression<bool, Tbl> _cmp(String op, T value) =>
      Expression(BinaryNode(node, op, ParamNode(type.encode(value))));
}

/// An ordinary value column.
final class ValueColumn<T, Tbl> extends Column<T, Tbl> {
  @override
  final String table;
  @override
  final String name;
  @override
  final SqlType<T> type;
  const ValueColumn(this.table, this.name, this.type);
}

/// A primary-key column.
final class PrimaryKey<T, Tbl> extends Column<T, Tbl> {
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
final class Ref<T, Tbl, Target> extends Column<T, Tbl> {
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
extension TextColumn<Tbl> on Column<String, Tbl> {
  Expression<bool, Tbl> like(String pattern) =>
      Expression(BinaryNode(node, 'LIKE', ParamNode(pattern)));
}

/// A column-scoped assignment (`column = value`) for INSERT/UPDATE. The value is
/// already encoded; `Tbl` keeps it bound to its table.
final class ColumnValue<Tbl> {
  final String column;
  final Object? encoded;
  const ColumnValue(this.column, this.encoded);
}

/// Lightweight table descriptor used by `insertInto`/`update`/`deleteFrom` and
/// as the FROM clause of joins.
final class TableRef<Tbl> {
  final String name;
  const TableRef(this.name);
}
