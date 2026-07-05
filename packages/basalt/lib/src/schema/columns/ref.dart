part of '../table.dart';

/// A foreign-key column on `Tbl` that references the [PrimaryKey] of `Target`.
/// Referencing the PK column object (a leaf) keeps it const-cycle free even for
/// mutual foreign keys, and the shared `T` enforces matching key types.
final class Ref<T, Tbl, Target> extends TableColumn<T, Tbl> {
  @override
  final String table;
  @override
  final String name;
  @override
  final SqlType<T> type;
  final PrimaryKey<T, Target> references;
  const Ref(this.table, this.name, this.type, {required this.references});
}
