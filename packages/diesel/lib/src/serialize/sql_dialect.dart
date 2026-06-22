/// SQL-dialect differences the serializer must account for. Keeping this behind
/// an interface is the seam that lets each backend (SQLite, Postgres, ...) plug
/// in its own quoting and placeholder style without touching the query builder.
/// Concrete implementations live in the backend packages (e.g. `diesel_sqlite`).
abstract interface class SqlDialect {
  /// Quote an identifier (table/column name).
  String quoteIdentifier(String name);

  /// Placeholder for the [index]-th (0-based) bound parameter.
  String placeholder(int index);
}
