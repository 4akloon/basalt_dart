part of '../table.dart';

/// An ordinary value column.
///
/// {@category schema}
final class ValueColumn<T, Tbl> extends TableColumn<T, Tbl> {
  const ValueColumn(this.owner, this.name, this.type);
  @override
  final QuerySource<Tbl> owner;
  @override
  final String name;
  @override
  final SqlType<T> type;
}
