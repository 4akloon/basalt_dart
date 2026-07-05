part of '../sql_node.dart';

/// One `ORDER BY` term.
final class Ordering {
  final ColumnNode column;
  final bool ascending;
  const Ordering(this.column, {this.ascending = true});
}
