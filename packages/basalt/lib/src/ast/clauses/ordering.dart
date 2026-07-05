part of '../sql_node.dart';

/// One `ORDER BY` term.
final class Ordering {
  const Ordering(this.column, {this.ascending = true});
  final ColumnNode column;
  final bool ascending;
}
