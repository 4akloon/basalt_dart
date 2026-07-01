import '../ast/sql_node.dart';
import '../expression/expression.dart';
import '../schema/table.dart';
import 'query.dart';
import 'row_reader.dart';

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

  /// Encoded value tuples — one list per row (a single-row insert has one).
  final List<List<Object?>> rows = [];

  /// `ON CONFLICT` target columns (`null` = no upsert clause).
  List<String>? conflictTarget;

  /// `ON CONFLICT ... DO NOTHING` when true; otherwise `DO UPDATE SET`.
  bool conflictDoNothing = false;

  /// Assignments for `DO UPDATE SET` (a literal via `set`, or `excluded.col` via
  /// `setToExcluded`).
  final List<ColumnValue<Object?>> conflictSet = [];

  InsertStatement(this.table);

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
  OnConflict<Tbl> onConflict(
          [List<TableColumn<Object?, Object?>> target = const []]) =>
      OnConflict._(this, [for (final c in target) c.name]);
}

/// Fluent builder for an `ON CONFLICT` clause (from [InsertStatement.onConflict]).
final class OnConflict<Tbl> {
  final InsertStatement<Tbl> _insert;
  final List<String> _target;
  OnConflict._(this._insert, this._target);

  /// `ON CONFLICT [(target)] DO NOTHING`.
  InsertStatement<Tbl> doNothing() {
    _insert.conflictTarget = _target;
    _insert.conflictDoNothing = true;
    return _insert;
  }

  /// `ON CONFLICT (target) DO UPDATE SET ...`. Use `col.set(v)` for a literal or
  /// `col.setToExcluded()` to take the failed row's proposed value.
  InsertStatement<Tbl> doUpdate(List<ColumnValue<Tbl>> assignments) {
    _insert.conflictTarget = _target;
    _insert.conflictSet.addAll(assignments);
    return _insert;
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

/// Attaches a `RETURNING` clause to any write statement.
extension WriteReturning on WriteStatement {
  /// Return the given columns of the affected table after the write. Finish with
  /// `.map(...)` / `.mapWith(...)`, then run via `Connection.executeReturning`:
  /// ```dart
  /// final id = (await db.executeReturning(
  ///   insertInto(Users.table).value(Users.name.set('Bob'))
  ///       .returning([Users.id]).map((r) => r.get(Users.id)),
  /// )).single;
  /// ```
  Returning returning(List<TableColumn<Object?, Object?>> columns) =>
      Returning(this, columns);
}

/// Intermediate builder from [WriteReturning.returning]; call [map] / [mapWith]
/// to attach a row decoder and produce an executable [ReturningQuery].
final class Returning {
  final WriteStatement _statement;
  final List<TableColumn<Object?, Object?>> _columns;
  const Returning(this._statement, this._columns);

  ReturningQuery<R> map<R>(R Function(RowReader reader) decode) =>
      ReturningQuery._(
        _statement,
        [
          for (final c in _columns)
            Projection(c.selectExpression, alias: c.selectAlias),
        ],
        {for (var i = 0; i < _columns.length; i++) _columns[i].readKey: i},
        decode,
      );

  ReturningQuery<R> mapWith<R>(RowMapper<R> mapper) => map(mapper.read);
}

/// A write statement finished with a `RETURNING` projection and a row decoder —
/// the executable analog of `MappedQuery` for INSERT/UPDATE/DELETE.
final class ReturningQuery<R> {
  final WriteStatement statement;
  final List<Projection> returning;
  final Map<String, int> _columnIndex;
  final R Function(RowReader reader) _decode;
  ReturningQuery._(
      this.statement, this.returning, this._columnIndex, this._decode);

  R Function(List<Object?> row) get rowDecoder =>
      (row) => _decode(RowReader(_columnIndex, row));
}
