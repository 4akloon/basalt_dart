part of '../table.dart';

/// A primary-key column.
final class PrimaryKey<T, Tbl> extends TableColumn<T, Tbl> {
  const PrimaryKey(this.table, this.name, this.type);
  @override
  final String table;
  @override
  final String name;
  @override
  final SqlType<T> type;
}
