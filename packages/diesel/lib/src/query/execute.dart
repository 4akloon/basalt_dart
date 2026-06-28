import '../connection.dart';
import 'query.dart';

/// diesel-style terminal helpers so a finished query reads like `query.load(db)`
/// / `query.first(db)` / `query.optional(db)`.
///
/// These live in their own library (an extension on [MappedQuery]) so the core
/// query builder stays free of any [Connection] dependency — preserving the
/// build-vs-execute separation. They're re-exported from `package:diesel/diesel.dart`.
extension MappedQueryExecute<R> on MappedQuery<R> {
  /// Runs the query and returns every row (diesel's `load`).
  Future<List<R>> load(Connection db) => db.fetch(this);

  /// Runs the query (capped at one row) and returns the first, throwing a
  /// [StateError] if the result set is empty (diesel's `first`).
  Future<R> first(Connection db) async {
    final rows = await limit(1).load(db);
    if (rows.isEmpty) {
      throw StateError('first(): the query returned no rows');
    }
    return rows.first;
  }

  /// Like [first] but returns `null` instead of throwing when empty
  /// (diesel's `first(...).optional()`).
  Future<R?> optional(Connection db) async {
    final rows = await limit(1).load(db);
    return rows.isEmpty ? null : rows.first;
  }
}
