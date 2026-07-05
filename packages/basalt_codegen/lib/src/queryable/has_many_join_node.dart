/// One JOIN in a has-many fold query tree.
final class HasManyJoinNode {
  const HasManyJoinNode({
    required this.aliasPath,
    required this.tableMarker,
    required this.dartVar,
    required this.joinKind,
    required this.onLeft,
    required this.onRight,
  });
  final String aliasPath;
  final String tableMarker;
  final String dartVar;
  final String joinKind;
  final String onLeft;
  final String onRight;
}
