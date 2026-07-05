part of '../sql_node.dart';

/// Reference to a table column, e.g. `"users"."age"`.
final class ColumnNode extends SqlNode {
  const ColumnNode(this.table, this.name);
  final String table;
  final String name;
}
