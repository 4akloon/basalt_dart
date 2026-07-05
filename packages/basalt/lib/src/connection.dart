import 'dart:async';

import 'query/query.dart';
import 'query/write.dart';
import 'schema/introspection.dart';

/// Database-agnostic execution surface. The query builder produces statements;
/// a `Connection` implementation serializes and runs them against a driver.
///
/// The API is async-first: SQLite runs synchronously under the hood and simply
/// returns already-completed futures, while an async driver (Postgres) fits the
/// exact same signatures with no breaking change. `FutureOr` appears only on the
/// transaction callback, so both sync and async bodies work.
///
/// {@category connection}
abstract interface class Connection {
  /// Runs a `SELECT` (single-table or joined) and maps each row to `R`.
  Future<List<R>> fetch<R>(SelectQuery<R> statement);

  /// Runs an INSERT/UPDATE/DELETE and returns the affected-row count.
  Future<int> execute(WriteStatement statement);

  /// Runs an INSERT/UPDATE/DELETE ... RETURNING and maps each returned row to
  /// `R` (build with `stmt.returning([...]).map(...)`).
  Future<List<R>> executeReturning<R>(ReturningQuery<R> statement);

  /// Escape hatch for raw SQL (DDL, migrations).
  Future<void> executeSql(String sql, [List<Object?> params]);

  /// Escape hatch for raw read queries (introspection, ad-hoc SQL). Each row is
  /// a `column-name -> value` map.
  Future<List<Map<String, Object?>>> queryRaw(String sql, [List<Object?> params]);

  /// Reads the database schema into a dialect-neutral model (for codegen).
  /// Each backend maps its own catalog and native types into the canonical form.
  Future<List<IntrospectedTable>> introspect();

  /// Runs [action] in a transaction, committing on success and rolling back on
  /// error. Nested calls use SAVEPOINTs.
  Future<T> transaction<T>(FutureOr<T> Function(Connection tx) action);

  Future<void> close();
}
