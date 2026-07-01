part of '../sql_node.dart';

/// `target BETWEEN low AND high`. [low]/[high] are already encoded.
final class BetweenNode extends SqlNode {
  final SqlNode target;
  final Object? low;
  final Object? high;
  const BetweenNode(this.target, this.low, this.high);
}
