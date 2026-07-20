import 'package:basalt/basalt.dart';

import 'inspector_exception.dart';

/// Resolves table and column names against a connection's introspected schema,
/// rejecting unknown identifiers (which cannot be parameterized) up front.
final class SchemaLookup {
  /// Creates a lookup over [_conn]'s schema.
  const SchemaLookup(this._conn);

  final Connection _conn;

  /// The introspected table named [name], or throws [InspectorException].
  Future<IntrospectedTable> table(String name) async {
    for (final t in await _conn.introspect()) {
      if (t.name == name) return t;
    }
    throw InspectorException('Unknown table: $name');
  }

  /// The column named [name] on [table], or throws [InspectorException].
  static IntrospectedColumn column(IntrospectedTable table, String name) {
    for (final c in table.columns) {
      if (c.name == name) return c;
    }
    throw InspectorException('Unknown column: $name');
  }
}
