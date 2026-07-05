import 'relation_edge.dart';

/// One node in the unrolled join tree for a relation query.
final class TreeNode {
  const TreeNode({
    required this.edge,
    required this.aliasPath,
    required this.parentAliasPath,
    required this.budget,
  });
  final RelationEdge edge;
  final String aliasPath;
  final String? parentAliasPath;
  final int budget;
}
