import 'class_info.dart';
import 'has_many_join_builder.dart';

/// Emits a [FoldMappedQuery] getter with JOIN tree + [mapFold].
final class HasManyQueryEmitter {
  const HasManyQueryEmitter({
    this.joinBuilder = const HasManyJoinBuilder(),
  });
  final HasManyJoinBuilder joinBuilder;

  String emit({
    required ClassInfo root,
    required Map<String, ClassInfo> classInfos,
    required String queryName,
    required String foldName,
  }) {
    final nodes = joinBuilder.build(root: root, classInfos: classInfos);
    final decls = <String>{
      for (final n in nodes)
        'final ${n.dartVar} = ${n.tableMarker}.table.aliased(\'${n.aliasPath}\');',
    };

    final joins = [
      for (final n in nodes)
        '.${n.joinKind}(${n.dartVar}, on: ${n.onLeft}.eqColumn(${n.onRight}),)',
    ];

    final pk = root.pkColumnExpr;
    final rootPk = pk == null ? '' : '.withRootPk($pk)';

    return '''
FoldMappedQuery<${root.className}> get $queryName {
${decls.map((d) => '  $d').join('\n')}
  return from(${root.tableMarker}.table)
${joins.map((j) => '      $j').join('\n')}
      .mapFold($foldName)$rootPk;
}
''';
  }
}
