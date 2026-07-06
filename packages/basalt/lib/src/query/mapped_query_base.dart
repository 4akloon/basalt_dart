part of 'query.dart';

/// Shared surface of the two executable query shapes ([MappedQuery] and
/// [FoldMappedQuery]): the wrapped [Query], the projection index, the
/// delegating [SelectQuery] getters, and the refining chainers.
///
/// `Self` is the concrete subclass (F-bounded), so every chainer returns the
/// caller's own type; `Row` is what the serializer and `Connection.fetch` see
/// per SQL row ([SelectQuery]'s type argument).
abstract base class _MappedQueryBase<Self extends _MappedQueryBase<Self, Row>,
    Row> implements SelectQuery<Row> {
  _MappedQueryBase(Query<dynamic> query)
      : _query = query,
        _columnIndex = {
          for (var i = 0; i < query.projection.length; i++)
            query.projection[i].readKey: i,
        };

  final Query<dynamic> _query;
  final Map<String, int> _columnIndex;

  /// Rebuilds `Self` around a refined [Query] (self-type factory).
  Self _withQuery(Query<dynamic> query);

  /// A [RowReader] over this query's projection — subclasses build their
  /// [rowDecoder] on top of it.
  RowReader _reader(List<Object?> row) => RowReader(_columnIndex, row);

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
  int? get limitCount => _query.limitCount;
  @override
  int? get offsetCount => _query.offsetCount;

  Self where(Expression<bool, dynamic> predicate) =>
      _withQuery(_query.where(predicate));

  /// basalt-style `filter`: ANDs with any existing predicate (see [Query.filter]).
  Self filter(Expression<bool, dynamic> predicate) =>
      _withQuery(_query.filter(predicate));

  Self orderBy(Ordering ordering) => _withQuery(_query.orderBy(ordering));

  /// basalt-style alias for [orderBy] (appends an ordering).
  Self order(Ordering ordering) => orderBy(ordering);

  /// basalt-style find-by-key (see [Query.findBy]).
  Self findBy<T>(TableColumn<T, dynamic> key, T value) =>
      filter(key.eq(value));

  Self limit(int count) => _withQuery(_query.limit(count));

  Self offset(int count) => _withQuery(_query.offset(count));
}
