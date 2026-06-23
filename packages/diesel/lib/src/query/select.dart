import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../schema/table.dart';

/// The shape the serializer and `Connection` consume, implemented by both the
/// single-table [SelectStatement] and the multi-table [JoinedSelect].
abstract interface class SelectQuery<R> {
  String get fromTable;
  List<Join> get joins;
  List<ColumnNode> get projection;
  SqlNode? get whereNode;
  List<Ordering> get orderings;
  int? get limitCount;
  int? get offsetCount;
  R Function(List<Object?> row) get rowDecoder;
}

/// An immutable, typed single-table `SELECT`.
///
/// `R` is the row type (a scalar for one column, a Dart record for several).
/// `Tbl` scopes `where`/`orderBy` to columns of the same table — full
/// compile-time safety. Build via the top-level `select1`..`select5` helpers.
final class SelectStatement<R, Tbl> implements SelectQuery<R> {
  @override
  final String fromTable;
  @override
  final List<ColumnNode> projection;
  @override
  final R Function(List<Object?> row) rowDecoder;
  @override
  final SqlNode? whereNode;
  @override
  final List<Ordering> orderings;
  @override
  final int? limitCount;
  @override
  final int? offsetCount;

  @override
  List<Join> get joins => const [];

  const SelectStatement({
    required this.fromTable,
    required this.projection,
    required this.rowDecoder,
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
        fromTable: fromTable,
        projection: projection,
        rowDecoder: rowDecoder,
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
      fromTable: a.table,
      projection: [a.node],
      rowDecoder: (r) => a.type.decode(r[0]),
    );

SelectStatement<(A, B), Tbl> select2<A, B, Tbl>(
        Column<A, Tbl> a, Column<B, Tbl> b) =>
    SelectStatement(
      fromTable: a.table,
      projection: [a.node, b.node],
      rowDecoder: (r) => (a.type.decode(r[0]), b.type.decode(r[1])),
    );

SelectStatement<(A, B, C), Tbl> select3<A, B, C, Tbl>(
        Column<A, Tbl> a, Column<B, Tbl> b, Column<C, Tbl> c) =>
    SelectStatement(
      fromTable: a.table,
      projection: [a.node, b.node, c.node],
      rowDecoder: (r) =>
          (a.type.decode(r[0]), b.type.decode(r[1]), c.type.decode(r[2])),
    );

SelectStatement<(A, B, C, D), Tbl> select4<A, B, C, D, Tbl>(Column<A, Tbl> a,
        Column<B, Tbl> b, Column<C, Tbl> c, Column<D, Tbl> d) =>
    SelectStatement(
      fromTable: a.table,
      projection: [a.node, b.node, c.node, d.node],
      rowDecoder: (r) => (
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
      fromTable: a.table,
      projection: [a.node, b.node, c.node, d.node, e.node],
      rowDecoder: (r) => (
        a.type.decode(r[0]),
        b.type.decode(r[1]),
        c.type.decode(r[2]),
        d.type.decode(r[3]),
        e.type.decode(r[4]),
      ),
    );

// --- Joins -----------------------------------------------------------------
//
// A joined query spans several tables, so its scope can't be a single `Tbl`
// marker (Dart has no type-level set membership). Instead the projection /
// predicate columns are accepted at the relaxed `Object?` scope (every
// `Column<_, X>` is a `Column<_, Object?>` by covariance), and the serializer
// verifies at build time that each referenced table is actually in the
// FROM/JOIN clause. Single-table queries keep their strict `Tbl` safety.

/// Start a join from a base table: `Users.table.innerJoin(Posts.table, on: ...)`.
extension TableJoins<Tbl> on TableRef<Tbl> {
  JoinSource innerJoin<Other>(TableRef<Other> other,
          {required Expression<bool, Object?> on}) =>
      JoinSource(name, [Join(JoinKind.inner, other.name, on.node)]);

  JoinSource leftJoin<Other>(TableRef<Other> other,
          {required Expression<bool, Object?> on}) =>
      JoinSource(name, [Join(JoinKind.left, other.name, on.node)]);

  /// FK-driven join: the target table and `ON` condition are derived from [fk],
  /// a foreign key on *this* table — `Posts.table.innerJoinOn(Posts.authorId)`.
  /// Only a [Ref] of this table is accepted, so you can't join on the wrong
  /// column or to the wrong table.
  JoinSource innerJoinOn<T, Target>(Ref<T, Tbl, Target> fk) =>
      JoinSource(name, [_fkJoin(JoinKind.inner, fk)]);

  JoinSource leftJoinOn<T, Target>(Ref<T, Tbl, Target> fk) =>
      JoinSource(name, [_fkJoin(JoinKind.left, fk)]);
}

Join _fkJoin<T, Tbl, Target>(JoinKind kind, Ref<T, Tbl, Target> fk) => Join(
      kind,
      fk.references.table,
      BinaryNode(fk.node, '=', fk.references.node),
    );

/// Accumulates a base table plus its joins; chain more joins, then project.
final class JoinSource {
  final String fromTable;
  final List<Join> joins;
  const JoinSource(this.fromTable, this.joins);

  JoinSource innerJoin<Other>(TableRef<Other> other,
          {required Expression<bool, Object?> on}) =>
      JoinSource(fromTable, [...joins, Join(JoinKind.inner, other.name, on.node)]);

  JoinSource leftJoin<Other>(TableRef<Other> other,
          {required Expression<bool, Object?> on}) =>
      JoinSource(fromTable, [...joins, Join(JoinKind.left, other.name, on.node)]);

  JoinedSelect<A> select1<A>(Column<A, Object?> a) => JoinedSelect(
        fromTable: fromTable,
        joins: joins,
        projection: [a.node],
        rowDecoder: (r) => a.type.decode(r[0]),
      );

  JoinedSelect<(A, B)> select2<A, B>(
          Column<A, Object?> a, Column<B, Object?> b) =>
      JoinedSelect(
        fromTable: fromTable,
        joins: joins,
        projection: [a.node, b.node],
        rowDecoder: (r) => (a.type.decode(r[0]), b.type.decode(r[1])),
      );

  JoinedSelect<(A, B, C)> select3<A, B, C>(
          Column<A, Object?> a, Column<B, Object?> b, Column<C, Object?> c) =>
      JoinedSelect(
        fromTable: fromTable,
        joins: joins,
        projection: [a.node, b.node, c.node],
        rowDecoder: (r) =>
            (a.type.decode(r[0]), b.type.decode(r[1]), c.type.decode(r[2])),
      );

  JoinedSelect<(A, B, C, D)> select4<A, B, C, D>(Column<A, Object?> a,
          Column<B, Object?> b, Column<C, Object?> c, Column<D, Object?> d) =>
      JoinedSelect(
        fromTable: fromTable,
        joins: joins,
        projection: [a.node, b.node, c.node, d.node],
        rowDecoder: (r) => (
          a.type.decode(r[0]),
          b.type.decode(r[1]),
          c.type.decode(r[2]),
          d.type.decode(r[3]),
        ),
      );
}

/// An immutable multi-table `SELECT`. Scope is relaxed (`where`/`orderBy` accept
/// columns of any participating table); the serializer validates membership.
final class JoinedSelect<R> implements SelectQuery<R> {
  @override
  final String fromTable;
  @override
  final List<Join> joins;
  @override
  final List<ColumnNode> projection;
  @override
  final R Function(List<Object?> row) rowDecoder;
  @override
  final SqlNode? whereNode;
  @override
  final List<Ordering> orderings;
  @override
  final int? limitCount;
  @override
  final int? offsetCount;

  const JoinedSelect({
    required this.fromTable,
    required this.joins,
    required this.projection,
    required this.rowDecoder,
    this.whereNode,
    this.orderings = const [],
    this.limitCount,
    this.offsetCount,
  });

  JoinedSelect<R> where(Expression<bool, Object?> predicate) =>
      _copy(whereNode: predicate.node);

  JoinedSelect<R> orderBy(Ordering ordering) =>
      _copy(orderings: [...orderings, ordering]);

  JoinedSelect<R> limit(int count) => _copy(limitCount: count);
  JoinedSelect<R> offset(int count) => _copy(offsetCount: count);

  JoinedSelect<R> _copy({
    SqlNode? whereNode,
    List<Ordering>? orderings,
    int? limitCount,
    int? offsetCount,
  }) =>
      JoinedSelect(
        fromTable: fromTable,
        joins: joins,
        projection: projection,
        rowDecoder: rowDecoder,
        whereNode: whereNode ?? this.whereNode,
        orderings: orderings ?? this.orderings,
        limitCount: limitCount ?? this.limitCount,
        offsetCount: offsetCount ?? this.offsetCount,
      );
}
