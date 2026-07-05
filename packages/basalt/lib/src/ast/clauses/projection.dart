part of '../sql_node.dart';

/// One item in a SELECT projection: an [expression] plus an optional `AS` [alias].
/// Built from a `Selection` so the serializer stays purely AST-level.
final class Projection {
  final SqlNode expression;
  final String? alias;
  const Projection(this.expression, {this.alias});
}
