part of 'table.dart';

/// An aliased table for self-joins (the same table joined more than once).
/// Columns are rebound to the alias, so `sender.col(Users.id)` serializes as
/// `"sender"."id"` and is distinct from `recipient.col(Users.id)`.
///
/// {@category schema}
final class TableAlias<Tbl> implements QuerySource<Tbl> {
  const TableAlias(this.alias, this.base);
  @override
  final String alias;
  final TableRef<Tbl> base;

  @override
  String get table => base.name;

  @override
  List<TableColumn<Object?, Object?>> get columns => [
        for (final c in base.columns)
          ValueColumn<Object?, Tbl>(alias, c.name, c.type),
      ];

  /// An alias-bound version of one of the base table's columns.
  @override
  TableColumn<T, Tbl> col<T>(TableColumn<T, Tbl> column) =>
      ValueColumn<T, Tbl>(alias, column.name, column.type);
}
