part of '../write.dart';

/// `INSERT INTO table (...) VALUES (...)`.
///
/// Build with `insertInto(Users.table).value(Users.name.set('Bob'))`. Each
/// assignment is produced by a column, so its value type is checked statically.
///
/// {@category writes}
final class InsertStatement<Tbl> extends WriteStatement {
  InsertStatement(this.table);
  final String table;
  final List<String> columns = [];

  /// Encoded value tuples — one list per row (a single-row insert has one).
  final List<List<Object?>> rows = [];

  /// `ON CONFLICT` target columns (`null` = no upsert clause).
  List<String>? conflictTarget;

  /// `ON CONFLICT ... DO NOTHING` when true; otherwise `DO UPDATE SET`.
  bool conflictDoNothing = false;

  /// Assignments for `DO UPDATE SET` (a literal via `set`, or `excluded.col` via
  /// `setToExcluded`).
  final List<ColumnValue<Object?>> conflictSet = [];

  /// Sets one column of a single-row insert; repeated calls build that row.
  InsertStatement<Tbl> value(ColumnValue<Tbl> assignment) {
    if (rows.isEmpty) rows.add(<Object?>[]);
    if (rows.length == 1) columns.add(assignment.column);
    rows.first.add(assignment.encoded);
    return this;
  }

  /// Batch insert: each element is one row's assignments. Columns are taken from
  /// the first row; every row must use the same columns in the same order. Don't
  /// mix with [value].
  InsertStatement<Tbl> values(Iterable<Iterable<ColumnValue<Tbl>>> valueRows) {
    for (final row in valueRows) {
      final encoded = <Object?>[];
      final recordColumns = columns.isEmpty && rows.isEmpty;
      for (final assignment in row) {
        if (recordColumns) columns.add(assignment.column);
        encoded.add(assignment.encoded);
      }
      rows.add(encoded);
    }
    return this;
  }

  /// Begin an upsert: `ON CONFLICT (target)`. An empty [target] emits a bare
  /// `ON CONFLICT`. Finish with [OnConflict.doNothing] or [OnConflict.doUpdate].
  OnConflict<Tbl> onConflict([
    List<TableColumn<Object?, Object?>> target = const [],
  ]) =>
      OnConflict._(this, [for (final c in target) c.name]);
}

InsertStatement<Tbl> insertInto<Tbl>(TableRef<Tbl> table) =>
    InsertStatement(table.name);
