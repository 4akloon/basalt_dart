part of '../sql_node.dart';

/// `target IN (v1, v2, ...)`. [values] are already encoded.
final class InNode extends SqlNode {
  final SqlNode target;
  final List<Object?> values;
  const InNode(this.target, this.values);
}
