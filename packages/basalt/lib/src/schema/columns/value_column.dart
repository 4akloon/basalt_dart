part of '../table.dart';

/// An ordinary value column.
final class ValueColumn<T, Tbl> extends TableColumn<T, Tbl> {
  @override
  final String table;
  @override
  final String name;
  @override
  final SqlType<T> type;
  const ValueColumn(this.table, this.name, this.type);
}
