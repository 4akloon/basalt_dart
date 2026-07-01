part of '../sql_node.dart';

/// A raw SQL fragment (escape hatch). [sql] is emitted verbatim; [params] are
/// appended as bound values in order — use `?` placeholders.
final class RawNode extends SqlNode {
  final String sql;
  final List<Object?> params;
  const RawNode(this.sql, this.params);
}
