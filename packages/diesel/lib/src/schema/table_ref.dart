part of 'table.dart';

/// Table descriptor: its name and full column list (the default projection for
/// `from`/joins). Cycle-safe even with foreign keys because [Ref] points at a
/// [PrimaryKey] leaf, not back at a `TableRef`.
final class TableRef<Tbl> implements QuerySource<Tbl> {
  final String name;
  @override
  final List<TableColumn<Object?, Object?>> columns;
  const TableRef(this.name, this.columns);

  @override
  String get table => name;
  @override
  String? get alias => null;

  @override
  TableColumn<T, Tbl> col<T>(TableColumn<T, Tbl> column) => column;

  /// Alias this table for a self-join — `Users.table.aliased('sender')`.
  TableAlias<Tbl> aliased(String alias) => TableAlias(alias, this);
}
