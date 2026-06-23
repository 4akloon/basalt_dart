/// Dialect-neutral description of a database schema, produced by
/// [Connection.introspect] and consumed by codegen (e.g. `print-schema`).
///
/// Each backend maps its own catalog and native types into this model, so the
/// code generator never needs to know SQLite vs Postgres specifics.
library;

/// Canonical column type — the backend normalizes its native type into one of
/// these, and codegen maps it to a Dart type + `SqlType`.
enum ColumnType { integer, text, real, boolean, blob, dateTime }

/// A foreign-key target discovered during introspection.
final class ForeignKey {
  final String table;

  /// Empty means "the target table's primary key".
  final String column;

  const ForeignKey(this.table, this.column);
}

final class IntrospectedColumn {
  final String name;

  /// Canonical type (mapped by the backend from its native type).
  final ColumnType type;

  /// The backend's original type string, kept for diagnostics.
  final String rawType;

  final bool isNullable;
  final bool isPrimaryKey;
  final ForeignKey? foreignKey;

  const IntrospectedColumn({
    required this.name,
    required this.type,
    required this.rawType,
    required this.isNullable,
    required this.isPrimaryKey,
    this.foreignKey,
  });
}

final class IntrospectedTable {
  final String name;
  final List<IntrospectedColumn> columns;
  const IntrospectedTable(this.name, this.columns);
}
