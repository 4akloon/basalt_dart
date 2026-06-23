import 'dart:async';

import 'query/select.dart';
import 'query/write.dart';

/// Database-agnostic execution surface. The query builder produces statements;
/// a `Connection` implementation serializes and runs them against a driver.
///
/// The API is async-first: SQLite runs synchronously under the hood and simply
/// returns already-completed futures, while an async driver (Postgres) fits the
/// exact same signatures with no breaking change. `FutureOr` appears only on the
/// transaction callback, so both sync and async bodies work.
abstract interface class Connection {
  /// Runs a `SELECT` (single-table or joined) and maps each row to `R`.
  Future<List<R>> fetch<R>(SelectQuery<R> statement);

  /// Runs an INSERT/UPDATE/DELETE and returns the affected-row count.
  Future<int> execute(WriteStatement statement);

  /// Escape hatch for raw SQL (DDL, migrations).
  Future<void> executeSql(String sql, [List<Object?> params]);

  /// Runs [action] in a transaction, committing on success and rolling back on
  /// error. Nested calls use SAVEPOINTs.
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action);

  Future<void> close();
}
