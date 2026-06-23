import '../schema/table.dart';

/// Reads typed values out of one result row, addressed **by column** (not by
/// position). This is what makes a single `map` decoder work for any number of
/// columns/tables: `r.get(Users.name)` returns a `String`, regardless of where
/// `name` sits in the projection, and joins stay unambiguous because each column
/// is keyed by `table.name`.
final class RowReader {
  /// `"table.column" -> index in the row`, precomputed once per query.
  final Map<String, int> _columnIndex;
  final List<Object?> _row;

  const RowReader(this._columnIndex, this._row);

  T get<T>(Column<T, Object?> column) {
    final index = _columnIndex['${column.table}.${column.name}'];
    if (index == null) {
      throw StateError('Column "${column.table}.${column.name}" is not in the '
          'query projection');
    }
    return column.type.decode(_row[index]);
  }
}
