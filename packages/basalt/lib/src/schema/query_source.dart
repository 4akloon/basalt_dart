part of 'table.dart';

/// Something a query can read FROM or JOIN: a real table ([TableRef]) or an
/// aliased one ([TableAlias]). `columns` are bound to the source's effective
/// name (`alias ?? tableName`), so reads/predicates address the right instance.
abstract interface class QuerySource<Tbl> {
  String get tableName; // real table name (FROM/JOIN target)
  String? get alias; // alias, or null
  List<TableColumn<Object?, Object?>> get columns;

  /// Rebinds a base-table column to this source's effective name (identity on
  /// [TableRef], alias-bound on [TableAlias]).
  TableColumn<T, Tbl> col<T>(TableColumn<T, Tbl> column);
}
