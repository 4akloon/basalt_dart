/// Untyped SQL expression tree.
///
/// The typed query-builder API ([Expression], [TableColumn]) produces these nodes,
/// and the serializer walks them to emit `(sql, params)`. Keeping the AST
/// untyped here lets the serializer stay simple and dialect-agnostic; all type
/// information lives in the builder layer above.
///
/// The sealed [SqlNode] hierarchy is split across `part` files (one node per
/// file under `nodes/`) so exhaustive `switch`es stay valid while each variant
/// lives on its own; the non-node clause helpers live under `clauses/`.
library;

part 'clauses/join.dart';
part 'clauses/ordering.dart';
part 'clauses/projection.dart';
part 'nodes/between_node.dart';
part 'nodes/binary_node.dart';
part 'nodes/column_node.dart';
part 'nodes/function_node.dart';
part 'nodes/in_node.dart';
part 'nodes/null_check_node.dart';
part 'nodes/param_node.dart';
part 'nodes/raw_node.dart';

/// A single node in a SQL expression tree.
sealed class SqlNode {
  const SqlNode();
}
