part of '../write.dart';

/// `UPDATE table SET ... WHERE ...`.
final class UpdateStatement<Tbl> extends WriteStatement {
  final String table;
  final List<String> assignColumns = [];
  final List<Object?> assignValues = [];
  SqlNode? whereNode;

  UpdateStatement(this.table);

  UpdateStatement<Tbl> value(ColumnValue<Tbl> assignment) {
    assignColumns.add(assignment.column);
    assignValues.add(assignment.encoded);
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
    UpdateStatement(table.name);
