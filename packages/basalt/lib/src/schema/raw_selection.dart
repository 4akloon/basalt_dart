part of 'table.dart';

/// A raw, typed SQL selection (escape hatch): emitted verbatim in the projection
/// and read back by its [readKey] (the [raw] `as` alias). Uses `?` placeholders.
///
/// {@category schema}
final class RawSelection<T> implements Selection<T> {
  const RawSelection(this._sql, this._params, this._alias, this.type);
  final String _sql;
  final List<Object?> _params;
  final String _alias;
  @override
  final SqlType<T> type;

  @override
  SqlNode get selectExpression => RawNode(_sql, _params);
  @override
  String? get selectAlias => _alias;
  @override
  String get readKey => _alias;
}

/// A raw typed SQL selection for `select([...])`, read back via `r.get(...)`.
/// Write valid SQL yourself (qualify columns); bind values with `?` + [params].
Selection<T> raw<T>(
  String sql,
  SqlType<T> type, {
  required String as,
  List<Object?> params = const [],
}) =>
    RawSelection(sql, params, as, type);

/// A raw boolean SQL fragment for `having` (and joined `where`/`filter`) — uses
/// the relaxed `Object?` scope; `?` placeholders bind [params] in order.
Expression<bool, Object?> rawCondition(
  String sql, {
  List<Object?> params = const [],
}) =>
    Expression(RawNode(sql, params));
