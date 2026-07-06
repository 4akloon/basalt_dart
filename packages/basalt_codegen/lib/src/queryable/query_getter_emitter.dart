import 'naming.dart';
import 'tree_node.dart';

/// Emits the constructor + `_build()`/`_decode` members of a `${Class}Query`
/// companion whose query joins the class's `@Relation` targets with aliased
/// joins.
final class QueryGetterEmitter {
  const QueryGetterEmitter();

  String emit({
    required String className,
    required String tableMarker,
    required int seedBudget,
    required List<TreeNode> treeNodes,
  }) {
    // The SQL alias keeps the underscored path (`author_manager`) so it matches
    // what the reader builds at runtime; the Dart variable holding it is
    // camelCased (`authorManager`) to stay a valid lowerCamelCase identifier.
    String varOf(String aliasPath) => camelCase(aliasPath);

    final aliasDecls = <String>{
      for (final node in treeNodes)
        "final ${varOf(node.aliasPath)} = ${node.edge.targetMarker}.table.aliased('${node.aliasPath}');",
    };

    final joinLines = <String>[];
    for (final node in treeNodes) {
      final onLeft = node.parentAliasPath == null
          ? '${node.edge.parentMarker}.${node.edge.fkAccessor}'
          : '${varOf(node.parentAliasPath!)}.col(${node.edge.parentMarker}.${node.edge.fkAccessor})';
      final onRight =
          '${varOf(node.aliasPath)}.col(${node.edge.targetMarker}.${node.edge.pkAccessor})';
      final join = node.edge.fkNullable ? 'leftJoin' : 'innerJoin';
      joinLines.add(
        '.$join(${varOf(node.aliasPath)}, on: $onLeft.eqColumn($onRight),)',
      );
    }

    final decls = aliasDecls.map((d) => '    $d').join('\n');
    final joins = joinLines.map((j) => '        $j').join('\n');

    return '''
  ${className}Query() : super(_build(), _decode);

  static Query<Object?> _build() {
$decls
    return from($tableMarker.table)
$joins;
  }

  static $className _decode(RowReader r) =>
      fromRow(r, $tableMarker.table, '', $seedBudget);
''';
  }
}
