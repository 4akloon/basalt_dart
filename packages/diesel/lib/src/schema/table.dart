import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../types/sql_type.dart';

/// A typed column belonging to table `Tbl`.
///
/// Columns are declared as `static const` on a table marker class so the very
/// same object can be used both by the query builder (`Users.age.gt(18)`) and,
/// later, inside derive annotations (`@MapColumn(Users.name)`) — annotation
/// arguments in Dart must be constants. `T` is the Dart value type; `Tbl` is a
/// phantom marker tying the column to its table.
final class Column<T, Tbl> {
  final String table;
  final String name;
  final SqlType<T> type;

  const Column(this.table, this.name, this.type);

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

  Ordering asc() => Ordering(node, ascending: true);
  Ordering desc() => Ordering(node, ascending: false);

  /// Produces a typed assignment for INSERT/UPDATE, e.g. `Users.age.set(31)`.
  ///
  /// The value type is pinned by this column's static type (no generic
  /// inference), so `Column<int>.set('x')` is a compile error — the leak a
  /// `value<T>(Column<T>, T)` signature would have via column covariance.
  ColumnValue<Tbl> set(T value) => ColumnValue(name, type.encode(value));

  Expression<bool, Tbl> _cmp(String op, T value) =>
      Expression(BinaryNode(node, op, ParamNode(type.encode(value))));
}

/// A column-scoped assignment (`column = value`) for INSERT/UPDATE. The value is
/// already encoded; `Tbl` keeps it bound to its table.
final class ColumnValue<Tbl> {
  final String column;
  final Object? encoded;
  const ColumnValue(this.column, this.encoded);
}

/// `LIKE` only makes sense for text columns.
extension TextColumn<Tbl> on Column<String, Tbl> {
  Expression<bool, Tbl> like(String pattern) =>
      Expression(BinaryNode(node, 'LIKE', ParamNode(pattern)));
}

/// Descriptor for a whole table, used by `insertInto` / `update` / `deleteFrom`
/// and by `selectAll`. Generated into `schema.dart` in Stage 3.
final class TableRef<Tbl> {
  final String name;
  final List<Column> columns;
  const TableRef(this.name, this.columns);
}
