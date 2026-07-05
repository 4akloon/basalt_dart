import 'class_info.dart';
import 'has_many_join_node.dart';
import 'naming.dart';
import 'relation_edge.dart';
import 'relation_tree_builder.dart';

/// Builds the full JOIN tree for a fold query (relations + has-many children).
final class HasManyJoinBuilder {
  const HasManyJoinBuilder();

  List<HasManyJoinNode> build({
    required ClassInfo root,
    required Map<String, ClassInfo> classInfos,
  }) {
    final nodes = <HasManyJoinNode>[];
    List<RelationEdge> edgesOf(String cls) =>
        classInfos[cls]?.ownEdges ?? const <RelationEdge>[];

    void addRelations(ClassInfo info, String prefix, {bool optional = false}) {
      if (info.ownEdges.isEmpty) return;
      final tree = RelationTreeBuilder(edgesOf).unrollRoots(info.ownEdges);
      for (final node in tree) {
        final fullAlias = prefix.isEmpty
            ? node.aliasPath
            : '${prefix}_${node.aliasPath}';
        final varName = camelCase(fullAlias);
        final parentVar = node.parentAliasPath == null
            ? (prefix.isEmpty ? info.tableMarker : camelCase(prefix))
            : camelCase(
                prefix.isEmpty
                    ? node.parentAliasPath!
                    : '${prefix}_${node.parentAliasPath}',
              );
        final onLeft = node.parentAliasPath == null
            ? (prefix.isEmpty
                ? '${node.edge.parentMarker}.${node.edge.fkAccessor}'
                : '$parentVar.col(${node.edge.parentMarker}.${node.edge.fkAccessor})')
            : '$parentVar.col(${node.edge.parentMarker}.${node.edge.fkAccessor})';
        final onRight =
            '$varName.col(${node.edge.targetMarker}.${node.edge.pkAccessor})';
        final joinKind = optional || node.edge.fkNullable
            ? 'leftJoin'
            : 'innerJoin';
        nodes.add(
          HasManyJoinNode(
            aliasPath: fullAlias,
            tableMarker: node.edge.targetMarker,
            dartVar: varName,
            joinKind: joinKind,
            onLeft: onLeft,
            onRight: onRight,
          ),
        );
      }
    }

    void walkChild(
      ClassInfo info,
      String prefix,
      String parentVar,
      String parentPkExpr,
    ) {
      addRelations(info, prefix, optional: true);
      for (final edge in info.hasManyEdges) {
        final alias =
            prefix.isEmpty ? edge.fieldName : '${prefix}_${edge.fieldName}';
        final varName = camelCase(alias);
        nodes.add(
          HasManyJoinNode(
            aliasPath: alias,
            tableMarker: edge.childMarker,
            dartVar: varName,
            joinKind: 'leftJoin',
            onLeft: '$varName.col(${edge.childFkColumnExpr})',
            onRight: '$parentVar.col($parentPkExpr)',
          ),
        );
        final child = classInfos[edge.childClass];
        final childPk = child?.pkColumnExpr;
        if (child != null && childPk != null) {
          walkChild(child, alias, varName, childPk);
        }
      }
    }

    addRelations(root, '');
    final rootPk = root.pkColumnExpr;
    if (rootPk == null) return nodes;

    for (final edge in root.hasManyEdges) {
      final alias = edge.fieldName;
      final varName = camelCase(alias);
        nodes.add(
          HasManyJoinNode(
            aliasPath: alias,
            tableMarker: edge.childMarker,
            dartVar: varName,
            joinKind: 'leftJoin',
            onLeft: '$varName.col(${edge.childFkColumnExpr})',
            onRight: rootPk,
          ),
        );
      final child = classInfos[edge.childClass];
      final childPk = child?.pkColumnExpr;
      if (child != null && childPk != null) {
        walkChild(child, alias, varName, childPk);
      }
    }

    return nodes;
  }
}
