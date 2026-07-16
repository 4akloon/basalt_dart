import '../types/sql_type.dart';

/// SQL-dialect differences the serializer must account for. Keeping this behind
/// an interface is the seam that lets each backend (SQLite, Postgres, ...) plug
/// in its own quoting and placeholder style without touching the query builder.
/// Concrete implementations live in the backend packages (e.g. `basalt_sqlite`).
///
/// {@category serialization}
abstract interface class SqlDialect {
  /// Quote an identifier (table/column name).
  String quoteIdentifier(String name);

  /// Placeholder for the [index]-th (0-based) bound parameter.
  String placeholder(int index);

  /// Converts an already-encoded (canonical) parameter to the form this backend's
  /// driver expects — SQLite maps `bool`→`int` and `DateTime`→epoch-ms, while
  /// Postgres passes them through natively. Applied to every bound value.
  Object? encodeParam(Object? value);

  /// Native type name used to `CAST` a bound parameter where the SQL context
  /// cannot infer its type — the columns of the `VALUES` table in a batch
  /// `updateAll`. Return `null` when this dialect needs no cast (SQLite's
  /// dynamic typing); Postgres maps each `SqlType` to its native type name so
  /// the statement stays preparable.
  String? castType(SqlType<Object?> type);
}
