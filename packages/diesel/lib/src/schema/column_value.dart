part of 'table.dart';

/// A column-scoped assignment (`column = value`) for INSERT/UPDATE. The value is
/// already encoded; `Tbl` keeps it bound to its table.
final class ColumnValue<Tbl> {
  final String column;
  final Object? encoded;

  /// When true this is an upsert `excluded.<column>` reference (no bound value)
  /// rather than a literal — see [TableColumn.setToExcluded].
  final bool isExcluded;
  const ColumnValue(this.column, this.encoded, {this.isExcluded = false});
}
