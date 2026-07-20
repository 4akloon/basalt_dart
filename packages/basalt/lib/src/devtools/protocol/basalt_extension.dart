/// The `ext.basalt.*` VM service extensions that make up the inspector protocol.
///
/// This is the single source of truth for the method names, shared by the host
/// (which registers each one) and every client (which calls them). Consumers
/// should reference [method] rather than hard-coding the string literals.
enum BasaltExtension {
  /// Lists the connections registered for inspection.
  listInstances('ext.basalt.listInstances'),

  /// Introspects one instance's schema.
  getSchema('ext.basalt.getSchema'),

  /// Reads one page of rows from a table.
  getTableData('ext.basalt.getTableData'),

  /// Updates a single row identified by its key columns.
  updateRow('ext.basalt.updateRow'),

  /// Runs an arbitrary SQL statement.
  runSql('ext.basalt.runSql');

  const BasaltExtension(this.method);

  /// Fully-qualified VM service extension method name (e.g. `ext.basalt.getSchema`).
  final String method;
}
