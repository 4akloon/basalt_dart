part of '../write.dart';

/// Fluent builder for an `ON CONFLICT` clause (from [InsertStatement.onConflict]).
///
/// {@category writes}
final class OnConflict<Tbl> {
  OnConflict._(this._insert, this._target);
  final InsertStatement<Tbl> _insert;
  final List<String> _target;

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
