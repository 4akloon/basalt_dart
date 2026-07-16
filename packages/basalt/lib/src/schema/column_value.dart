part of 'table.dart';

/// A column-scoped assignment (`column = value`) for INSERT/UPDATE. The value is
/// already encoded; `Tbl` keeps it bound to its table.
///
/// {@category schema}
final class ColumnValue<Tbl> {
  const ColumnValue(
    this.column,
    this.encoded, {
    this.isExcluded = false,
    this.valueExpr,
    this.type,
  });
  final String column;
  final Object? encoded;
  final SqlNode? valueExpr;

  /// When true this is an upsert `excluded.<column>` reference (no bound value)
  /// rather than a literal — see [TableColumn.setToExcluded].
  final bool isExcluded;

  /// The column's codec, when the assignment came from [TableColumn.set].
  /// Serialization uses it where a dialect needs an explicit parameter cast
  /// (the `VALUES` table of an `UpdateAllStatement` on Postgres).
  final SqlType<Object?>? type;
}
