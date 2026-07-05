part of '../sql_node.dart';

/// One `ORDER BY` term.
///
/// {@category queries}
final class Ordering {
  const Ordering(this.expression, {this.ascending = true});
  final SqlNode expression;
  final bool ascending;
}
