part of '../write.dart';

/// A write statement finished with a `RETURNING` projection and a row decoder —
/// the executable analog of `MappedQuery` for INSERT/UPDATE/DELETE.
final class ReturningQuery<R> {
  ReturningQuery._(
    this.statement,
    this.returning,
    this._columnIndex,
    this._decode,
  );
  final WriteStatement statement;
  final List<Projection> returning;
  final Map<String, int> _columnIndex;
  final R Function(RowReader reader) _decode;

  R Function(List<Object?> row) get rowDecoder =>
      (row) => _decode(RowReader(_columnIndex, row));
}
