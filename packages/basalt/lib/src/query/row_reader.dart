import '../schema/table.dart';

/// Reads typed values out of one result row, addressed **by selection** (a
/// column or an aggregate), not by position. This is what makes a single `map`
/// decoder work for any number of columns/tables: `r.get(Users.name)` returns a
/// `String` regardless of where `name` sits in the projection, joins stay
/// unambiguous (each column is keyed by `table.name`), and aggregates are keyed
/// by their alias.
///
/// {@category queries}
final class RowReader {
  const RowReader(this._columnIndex, this._row);

  /// `readKey -> index in the row`, precomputed once per query.
  final Map<String, int> _columnIndex;
  final List<Object?> _row;

  T get<T>(Selection<T> selection) {
    final index = _columnIndex[selection.readKey];
    if (index == null) {
      throw StateError('Selection "${selection.readKey}" is not in the '
          'query projection');
    }
    return selection.type.decode(_row[index]);
  }

  /// Whether [selection] is non-null in this row (e.g. a LEFT JOIN miss).
  bool isPresent(Selection<Object?> selection) {
    final index = _columnIndex[selection.readKey];
    if (index == null) return false;
    return _row[index] != null;
  }
}
