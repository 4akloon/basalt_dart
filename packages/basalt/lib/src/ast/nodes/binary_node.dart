part of '../sql_node.dart';

/// Binary infix operation: `left <op> right` (e.g. `=`, `>`, `AND`, `LIKE`).
final class BinaryNode extends SqlNode {
  const BinaryNode(this.left, this.op, this.right);
  final SqlNode left;
  final String op;
  final SqlNode right;
}
