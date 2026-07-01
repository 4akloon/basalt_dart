part of '../sql_node.dart';

/// Binary infix operation: `left <op> right` (e.g. `=`, `>`, `AND`, `LIKE`).
final class BinaryNode extends SqlNode {
  final SqlNode left;
  final String op;
  final SqlNode right;
  const BinaryNode(this.left, this.op, this.right);
}
