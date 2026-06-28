import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../schema/table.dart';

/// Statements that mutate rows and return an affected-row count rather than a
/// result set. Sealed so the serializer can exhaustively switch over them.
sealed class WriteStatement {
  const WriteStatement();
}

/// `INSERT INTO table (...) VALUES (...)`.
///
/// Build with `insertInto(Users.table).value(Users.name.set('Bob'))`. Each
/// assignment is produced by a column, so its value type is checked statically.
final class InsertStatement<Tbl> extends WriteStatement {
  final String table;
  final List<String> columns = [];
  final List<Object?> values = [];

  InsertStatement(this.table);

  InsertStatement<Tbl> value(ColumnValue<Tbl> assignment) {
    columns.add(assignment.column);
    values.add(assignment.encoded);
    return this;
  }
}

InsertStatement<Tbl> insertInto<Tbl>(TableRef<Tbl> table) =>
    InsertStatement(table.name);

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

  /// diesel-style alias for [value] (`update(t).set(col.set(v))`).
  UpdateStatement<Tbl> set(ColumnValue<Tbl> assignment) => value(assignment);

  UpdateStatement<Tbl> where(Expression<bool, Tbl> predicate) {
    whereNode = predicate.node;
    return this;
  }
}

UpdateStatement<Tbl> update<Tbl>(TableRef<Tbl> table) =>
    UpdateStatement(table.name);

/// `DELETE FROM table WHERE ...`.
final class DeleteStatement<Tbl> extends WriteStatement {
  final String table;
  SqlNode? whereNode;

  DeleteStatement(this.table);

  DeleteStatement<Tbl> where(Expression<bool, Tbl> predicate) {
    whereNode = predicate.node;
    return this;
  }
}

DeleteStatement<Tbl> deleteFrom<Tbl>(TableRef<Tbl> table) =>
    DeleteStatement(table.name);
