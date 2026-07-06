import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../schema/table.dart';
import 'row_reader.dart';

part 'fold_query.dart';
part 'mapped_query.dart';
part 'mapped_query_base.dart';

/// The shape the serializer and `Connection` consume. Implemented by the
/// terminal [MappedQuery] and [FoldMappedQuery]; [Query] is the builder that
/// produces them.
abstract interface class SelectQuery<R> {
  String get fromTable;
  String? get fromAlias;
  List<Join> get joins;
  List<Projection> get projection;
  bool get isDistinct;
  SqlNode? get whereNode;
  List<ColumnNode> get groupByColumns;
  SqlNode? get havingNode;
  List<Ordering> get orderings;
  int? get limitCount;
  int? get offsetCount;
  R Function(List<Object?> row) get rowDecoder;
}

/// A reusable, codegen-friendly row decoder for a data class. `@Queryable(Users)`
/// emits one of these (a single `read` built from `RowReader.get` calls). They
/// compose freely — a `Comment` reader can call a `Post` reader on the same
/// [RowReader] to nest objects, with no arity-specific machinery.
///
/// {@category queries}
final class RowMapper<R> {
  const RowMapper(this.read);
  final R Function(RowReader reader) read;
}

/// Immutable SELECT builder.
///
/// `Scope` is the table marker for a single-table query (so `where` stays
/// compile-time scoped to that table) and becomes `Object?` once joined (the
/// relaxed scope; the serializer then validates table membership at build time).
/// The projection defaults to every column of the involved tables; narrow it
/// with [select] (columns and/or aggregates). Call [map] to finish with a typed
/// row decoder.
///
/// {@category queries}
final class Query<Scope> {
  const Query({
    required this.fromTable,
    this.fromAlias,
    this.joins = const [],
    required this.projection,
    this.isDistinct = false,
    this.whereNode,
    this.groupByColumns = const [],
    this.havingNode,
    this.orderings = const [],
    this.limitCount,
    this.offsetCount,
  });
  final String fromTable;
  final String? fromAlias;
  final List<Join> joins;
  final List<Selection<Object?>> projection;
  final bool isDistinct;
  final SqlNode? whereNode;
  final List<TableColumn<Object?, Object?>> groupByColumns;
  final SqlNode? havingNode;
  final List<Ordering> orderings;
  final int? limitCount;
  final int? offsetCount;

  Query<Scope> where(Expression<bool, Scope> predicate) =>
      _copy(whereNode: predicate.node);

  Query<Scope> orderBy(Ordering ordering) =>
      _copy(orderings: [...orderings, ordering]);

  Query<Scope> limit(int count) => _copy(limitCount: count);
  Query<Scope> offset(int count) => _copy(offsetCount: count);

  /// basalt-style `filter`: ANDs with any existing predicate (unlike [where],
  /// which replaces). `filter(a).filter(b)` ⇒ `WHERE a AND b`.
  Query<Scope> filter(Expression<bool, Scope> predicate) {
    final existing = whereNode;
    return existing == null
        ? where(predicate)
        : _copy(whereNode: BinaryNode(existing, 'AND', predicate.node));
  }

  /// basalt-style alias for [orderBy] (appends an ordering).
  Query<Scope> order(Ordering ordering) => orderBy(ordering);

  /// basalt-style find-by-key: filter by [key] (typically the primary key); the
  /// value type is pinned by the column, so `findBy(Users.id, 'x')` is a compile
  /// error. ANDs with any existing predicate.
  Query<Scope> findBy<T>(TableColumn<T, Scope> key, T value) =>
      filter(key.eq(value));

  /// Emit `SELECT DISTINCT`.
  Query<Scope> distinct([bool value = true]) => _copy(distinct: value);

  /// `GROUP BY` the given columns — typically paired with aggregate selections
  /// in [select] and a [having] predicate.
  Query<Scope> groupBy(List<TableColumn<Object?, Object?>> columns) =>
      _copy(groupByColumns: columns);

  /// `HAVING` predicate over grouped rows (use with [groupBy]). Uses the relaxed
  /// `Object?` scope because HAVING is typically written over aggregates.
  Query<Scope> having(Expression<bool, Object?> predicate) =>
      _copy(havingNode: predicate.node);

  /// Narrow the projection to exactly [selections] — columns and/or aggregates
  /// (default is all columns of the involved tables).
  Query<Scope> select(List<Selection<Object?>> selections) =>
      _copy(projection: selections);

  /// INNER JOIN [other] (a [TableRef] or an aliased [TableAlias]). Provide the
  /// condition either explicitly (`on:`) or by a foreign key (`onFk:` — its
  /// `column = referenced-pk` becomes the `ON`). Use `on:` for self-joins.
  Query<Object?> innerJoin<Other>(
    QuerySource<Other> other, {
    Expression<bool, Object?>? on,
    Ref<Object?, Object?, Object?>? onFk,
  }) =>
      _join(JoinKind.inner, other, on, onFk);

  Query<Object?> leftJoin<Other>(
    QuerySource<Other> other, {
    Expression<bool, Object?>? on,
    Ref<Object?, Object?, Object?>? onFk,
  }) =>
      _join(JoinKind.left, other, on, onFk);

  Query<Object?> _join<Other>(
    JoinKind kind,
    QuerySource<Other> other,
    Expression<bool, Object?>? on,
    Ref<Object?, Object?, Object?>? onFk,
  ) {
    final SqlNode onNode;
    if (onFk case final fk?) {
      onNode = BinaryNode(fk.node, '=', fk.references.node);
    } else if (on case final predicate?) {
      onNode = predicate.node;
    } else {
      throw ArgumentError('innerJoin/leftJoin needs either on: or onFk:');
    }
    return Query<Object?>(
      fromTable: fromTable,
      fromAlias: fromAlias,
      joins: [...joins, Join(kind, other.table, onNode, alias: other.alias)],
      projection: [...projection, ...other.columns],
      isDistinct: isDistinct,
      whereNode: whereNode,
      groupByColumns: groupByColumns,
      havingNode: havingNode,
      orderings: orderings,
      limitCount: limitCount,
      offsetCount: offsetCount,
    );
  }

  /// Attach a row decoder. The result is still chainable via
  /// [MappedQuery.orderBy], [MappedQuery.limit], and friends.
  MappedQuery<R> map<R>(R Function(RowReader reader) decode) =>
      MappedQuery(this, decode);

  /// Like [map] but using a reusable [RowMapper] (the codegen output).
  MappedQuery<R> mapWith<R>(RowMapper<R> mapper) => map(mapper.read);

  Query<Scope> _copy({
    List<Selection<Object?>>? projection,
    bool? distinct,
    SqlNode? whereNode,
    List<TableColumn<Object?, Object?>>? groupByColumns,
    SqlNode? havingNode,
    List<Ordering>? orderings,
    int? limitCount,
    int? offsetCount,
  }) =>
      Query<Scope>(
        fromTable: fromTable,
        fromAlias: fromAlias,
        joins: joins,
        projection: projection ?? this.projection,
        isDistinct: distinct ?? isDistinct,
        whereNode: whereNode ?? this.whereNode,
        groupByColumns: groupByColumns ?? this.groupByColumns,
        havingNode: havingNode ?? this.havingNode,
        orderings: orderings ?? this.orderings,
        limitCount: limitCount ?? this.limitCount,
        offsetCount: offsetCount ?? this.offsetCount,
      );
}

/// Start a query from [source] (a table or an alias). Single-table scope keeps
/// `where` strictly typed.
Query<Tbl> from<Tbl>(QuerySource<Tbl> source) => Query<Tbl>(
      fromTable: source.table,
      fromAlias: source.alias,
      projection: [...source.columns],
    );
