part of '../table.dart';

/// A foreign-key column on `Tbl` that references the [PrimaryKey] of `Target`.
/// The const graph stays acyclic even for mutual/self foreign keys: a `Ref`
/// points at the target's [PrimaryKey] constant, whose own [owner] is a table
/// singleton that lists its columns only through a lazily-evaluated getter.
/// The shared `T` enforces matching key types.
///
/// {@category schema}
final class Ref<T, Tbl, Target> extends TableColumn<T, Tbl> {
  const Ref(this.owner, this.name, this.type, {required this.references});
  @override
  final QuerySource<Tbl> owner;
  @override
  final String name;
  @override
  final SqlType<T> type;
  final PrimaryKey<T, Target> references;
}
