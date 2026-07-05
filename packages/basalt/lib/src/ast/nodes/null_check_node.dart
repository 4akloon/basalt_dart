part of '../sql_node.dart';

/// `target IS NULL` / `target IS NOT NULL`.
final class NullCheckNode extends SqlNode {
  const NullCheckNode(this.target, {this.negated = false});
  final SqlNode target;
  final bool negated;
}
