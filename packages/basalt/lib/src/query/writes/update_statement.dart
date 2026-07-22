part of '../write.dart';

/// `UPDATE table SET ... WHERE ...`.
///
/// {@category writes}
final class UpdateStatement<Tbl> extends WriteStatement {
  UpdateStatement(this.table);
  final String table;
  final List<ColumnValue<Tbl>> assignments = [];
  SqlNode? whereNode;

  UpdateStatement<Tbl> value(ColumnValue<Tbl> assignment) {
    assignments.add(assignment);
    return this;
  }

  /// basalt-style alias for [value] (`update(t).set(col.set(v))`).
  UpdateStatement<Tbl> set(ColumnValue<Tbl> assignment) => value(assignment);

  UpdateStatement<Tbl> where(Expression<bool, Tbl> predicate) {
    whereNode = predicate.node;
    return this;
  }
}

UpdateStatement<Tbl> update<Tbl>(TableRef<Tbl> table) =>
    UpdateStatement(table.tableName);
