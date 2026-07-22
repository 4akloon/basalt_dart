part of '../table.dart';

/// A primary-key column.
///
/// {@category schema}
final class PrimaryKey<T, Tbl> extends TableColumn<T, Tbl> {
  const PrimaryKey(this.owner, this.name, this.type);
  @override
  final QuerySource<Tbl> owner;
  @override
  final String name;
  @override
  final SqlType<T> type;
}
