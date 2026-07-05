part of '../table.dart';

/// An ordinary value column.
final class ValueColumn<T, Tbl> extends TableColumn<T, Tbl> {
  const ValueColumn(this.table, this.name, this.type);
  @override
  final String table;
  @override
  final String name;
  @override
  final SqlType<T> type;
}
