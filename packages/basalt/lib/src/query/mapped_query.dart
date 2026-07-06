part of 'query.dart';

/// A [Query] finished with a decoder — the executable [SelectQuery].
///
/// Usually obtained via [Query.map]/[Query.mapWith]. The generative
/// constructor is public (and the class `base`, not `final`) so generated
/// query classes can `extends MappedQuery` and *be* the query:
/// `db.fetch(UserQuery())`.
///
/// {@category queries}
base class MappedQuery<R> extends _MappedQueryBase<MappedQuery<R>, R> {
  /// Wraps a built [query] with a row [decode]r. Application code normally
  /// reaches this through [Query.map]; subclassing is the codegen seam.
  MappedQuery(super.query, R Function(RowReader reader) decode)
      : _decode = decode;

  final R Function(RowReader reader) _decode;

  @override
  MappedQuery<R> _withQuery(Query<dynamic> query) => MappedQuery(query, _decode);

  @override
  R Function(List<Object?>) get rowDecoder => (row) => _decode(_reader(row));

  /// Emit `SELECT DISTINCT`.
  MappedQuery<R> distinct([bool value = true]) =>
      _withQuery(_query.distinct(value));

  /// `GROUP BY` the given columns (see [Query.groupBy]).
  MappedQuery<R> groupBy(List<TableColumn<Object?, Object?>> columns) =>
      _withQuery(_query.groupBy(columns));

  /// `HAVING` predicate over grouped rows (see [Query.having]).
  MappedQuery<R> having(Expression<bool, dynamic> predicate) =>
      _withQuery(_query.having(predicate));
}
