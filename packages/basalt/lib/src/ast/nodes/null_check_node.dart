part of '../sql_node.dart';

/// `target IS NULL` / `target IS NOT NULL`.
final class NullCheckNode extends SqlNode {
  final SqlNode target;
  final bool negated;
  const NullCheckNode(this.target, {this.negated = false});
}
