part of '../write.dart';

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
