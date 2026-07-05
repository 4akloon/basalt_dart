part of '../sql_node.dart';

/// A bound parameter. [value] is already encoded to a driver-ready value
/// (see [SqlType.encode]); the serializer only emits a placeholder for it.
final class ParamNode extends SqlNode {
  const ParamNode(this.value);
  final Object? value;
}
