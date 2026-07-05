part of '../sql_node.dart';

/// A function call, e.g. `COUNT(*)` or `SUM("users"."age")`. [argument] is null
/// for `COUNT(*)`.
final class FunctionNode extends SqlNode {
  const FunctionNode(this.name, this.argument);
  final String name;
  final SqlNode? argument;
}
