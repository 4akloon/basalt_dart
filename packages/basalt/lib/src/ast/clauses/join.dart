part of '../sql_node.dart';

enum JoinKind { inner, left }

/// A single `JOIN <table> [AS <alias>] ON <condition>` in a query's FROM clause.
/// [alias] is set when the same table is joined more than once (self-joins).
final class Join {
  const Join(this.kind, this.table, this.on, {this.alias});
  final JoinKind kind;
  final String table;
  final String? alias;
  final SqlNode on;
}
