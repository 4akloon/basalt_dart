import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../schema/table.dart';
import 'query.dart';
import 'row_reader.dart';

/// Folds a flat JOIN result set into parent rows (e.g. `@HasMany` codegen).
typedef RowFolder<R> = List<R> Function(List<RowReader> readers);

/// A JOIN [Query] whose SQL rows are folded into fewer parents via [fold].
///
/// Implements [SelectQuery] as `SelectQuery<RowReader>` so [Connection.fetch]
/// returns one [RowReader] per SQL row; call [FoldMappedQueryExecute.load] to
/// run the folder.
///
/// {@category queries}
final class FoldMappedQuery<R> implements SelectQuery<RowReader> {
  FoldMappedQuery._(
    this._query,
    this.fold, {
    this.rootPkColumn,
    this.parentLimit,
    this.parentOffset,
  }) : _columnIndex = {
          for (var i = 0; i < _query.projection.length; i++)
            _query.projection[i].readKey: i,
        };

  final Query<dynamic> _query;
  final RowFolder<R> fold;
  final Map<String, int> _columnIndex;

  /// Root primary key — drives parent-limit subquery serialization.
  final TableColumn<Object?, Object?>? rootPkColumn;
  final int? parentLimit;
  final int? parentOffset;

  @override
  String get fromTable => _query.fromTable;
  @override
  String? get fromAlias => _query.fromAlias;
  @override
  List<Join> get joins => _query.joins;
  @override
  List<Projection> get projection => [
        for (final s in _query.projection)
          Projection(s.selectExpression, alias: s.selectAlias),
      ];
  @override
  bool get isDistinct => _query.isDistinct;
  @override
  SqlNode? get whereNode => _query.whereNode;
  @override
  List<ColumnNode> get groupByColumns =>
      [for (final c in _query.groupByColumns) c.node];
  @override
  SqlNode? get havingNode => _query.havingNode;
  @override
  List<Ordering> get orderings => _query.orderings;
  @override
  int? get limitCount => null;
  @override
  int? get offsetCount => null;
  @override
  RowReader Function(List<Object?>) get rowDecoder =>
      (row) => RowReader(_columnIndex, row);

  FoldMappedQuery<R> _copyWith({
    Query<dynamic>? query,
    int? parentLimit,
    int? parentOffset,
    TableColumn<Object?, Object?>? rootPkColumn,
  }) =>
      FoldMappedQuery._(
        query ?? _query,
        fold,
        rootPkColumn: rootPkColumn ?? this.rootPkColumn,
        parentLimit: parentLimit ?? this.parentLimit,
        parentOffset: parentOffset ?? this.parentOffset,
      );

  FoldMappedQuery<R> orderBy(Ordering ordering) =>
      _copyWith(query: _query.orderBy(ordering));

  /// Limits **parent** rows (subquery on [rootPkColumn]), not flat SQL rows.
  FoldMappedQuery<R> limit(int count) => _copyWith(parentLimit: count);

  FoldMappedQuery<R> offset(int count) => _copyWith(parentOffset: count);

  FoldMappedQuery<R> where(Expression<bool, dynamic> predicate) =>
      _copyWith(query: _query.where(predicate));

  FoldMappedQuery<R> filter(Expression<bool, dynamic> predicate) =>
      _copyWith(query: _query.filter(predicate));

  FoldMappedQuery<R> order(Ordering ordering) => orderBy(ordering);

  FoldMappedQuery<R> findBy<T>(TableColumn<T, dynamic> key, T value) =>
      filter(key.eq(value));

  FoldMappedQuery<R> withRootPk(TableColumn<Object?, Object?> pk) =>
      _copyWith(rootPkColumn: pk);
}

/// Attach a row folder after JOINs — use [FoldMappedQueryExecute.load] to run.
extension QueryMapFold on Query<Object?> {
  FoldMappedQuery<R> mapFold<R>(RowFolder<R> fold) =>
      FoldMappedQuery._(this, fold);
}
