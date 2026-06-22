import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../schema/table.dart';

/// An immutable, typed `SELECT` statement.
///
/// `R` is the row type produced for each result (a scalar for one column, a
/// Dart record for several). `Tbl` scopes `where`/`orderBy` to columns of the
/// same table. Build instances via the top-level `select1`..`select5` helpers.
final class SelectStatement<R, Tbl> {
  final String table;
  final List<ColumnNode> projection;
  final R Function(List<Object?> row) decodeRow;
  final SqlNode? whereNode;
  final List<Ordering> orderings;
  final int? limitCount;
  final int? offsetCount;

  const SelectStatement({
    required this.table,
    required this.projection,
    required this.decodeRow,
    this.whereNode,
    this.orderings = const [],
    this.limitCount,
    this.offsetCount,
  });

  SelectStatement<R, Tbl> where(Expression<bool, Tbl> predicate) =>
      _copy(whereNode: predicate.node);

  SelectStatement<R, Tbl> orderBy(Ordering ordering) =>
      _copy(orderings: [...orderings, ordering]);

  SelectStatement<R, Tbl> limit(int count) => _copy(limitCount: count);
  SelectStatement<R, Tbl> offset(int count) => _copy(offsetCount: count);

  SelectStatement<R, Tbl> _copy({
    SqlNode? whereNode,
    List<Ordering>? orderings,
    int? limitCount,
    int? offsetCount,
  }) =>
      SelectStatement(
        table: table,
        projection: projection,
        decodeRow: decodeRow,
        whereNode: whereNode ?? this.whereNode,
        orderings: orderings ?? this.orderings,
        limitCount: limitCount ?? this.limitCount,
        offsetCount: offsetCount ?? this.offsetCount,
      );
}

// Dart has no variadic generics or function overloading, so we expose one
// helper per projection arity. The result type is a Dart record, mirroring
// Diesel's tuple-typed selects.

SelectStatement<A, Tbl> select1<A, Tbl>(Column<A, Tbl> a) => SelectStatement(
      table: a.table,
      projection: [a.node],
      decodeRow: (r) => a.type.decode(r[0]),
    );

SelectStatement<(A, B), Tbl> select2<A, B, Tbl>(
        Column<A, Tbl> a, Column<B, Tbl> b) =>
    SelectStatement(
      table: a.table,
      projection: [a.node, b.node],
      decodeRow: (r) => (a.type.decode(r[0]), b.type.decode(r[1])),
    );

SelectStatement<(A, B, C), Tbl> select3<A, B, C, Tbl>(
        Column<A, Tbl> a, Column<B, Tbl> b, Column<C, Tbl> c) =>
    SelectStatement(
      table: a.table,
      projection: [a.node, b.node, c.node],
      decodeRow: (r) =>
          (a.type.decode(r[0]), b.type.decode(r[1]), c.type.decode(r[2])),
    );

SelectStatement<(A, B, C, D), Tbl> select4<A, B, C, D, Tbl>(Column<A, Tbl> a,
        Column<B, Tbl> b, Column<C, Tbl> c, Column<D, Tbl> d) =>
    SelectStatement(
      table: a.table,
      projection: [a.node, b.node, c.node, d.node],
      decodeRow: (r) => (
        a.type.decode(r[0]),
        b.type.decode(r[1]),
        c.type.decode(r[2]),
        d.type.decode(r[3]),
      ),
    );

SelectStatement<(A, B, C, D, E), Tbl> select5<A, B, C, D, E, Tbl>(
        Column<A, Tbl> a,
        Column<B, Tbl> b,
        Column<C, Tbl> c,
        Column<D, Tbl> d,
        Column<E, Tbl> e) =>
    SelectStatement(
      table: a.table,
      projection: [a.node, b.node, c.node, d.node, e.node],
      decodeRow: (r) => (
        a.type.decode(r[0]),
        b.type.decode(r[1]),
        c.type.decode(r[2]),
        d.type.decode(r[3]),
        e.type.decode(r[4]),
      ),
    );
