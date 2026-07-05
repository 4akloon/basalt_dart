part of '../sql_node.dart';

/// Reference to a table column, e.g. `"users"."age"`.
final class ColumnNode extends SqlNode {
  final String table;
  final String name;
  const ColumnNode(this.table, this.name);
}
