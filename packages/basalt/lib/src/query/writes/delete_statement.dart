part of '../write.dart';

/// `DELETE FROM table WHERE ...`.
final class DeleteStatement<Tbl> extends WriteStatement {
  DeleteStatement(this.table);
  final String table;
  SqlNode? whereNode;

  DeleteStatement<Tbl> where(Expression<bool, Tbl> predicate) {
    whereNode = predicate.node;
    return this;
  }
}

DeleteStatement<Tbl> deleteFrom<Tbl>(TableRef<Tbl> table) =>
    DeleteStatement(table.name);
