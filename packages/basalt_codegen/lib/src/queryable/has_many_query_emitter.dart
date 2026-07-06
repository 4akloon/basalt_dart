import 'class_info.dart';
import 'has_many_join_builder.dart';

/// Emits the constructor + `_build()` members of a `${Class}Query` companion
/// extending `FoldMappedQuery`: the JOIN tree feeds the sibling static `fold`,
/// and the root PK goes to `rootPkColumn` (drives parent-row limit/offset).
final class HasManyQueryEmitter {
  const HasManyQueryEmitter({
    this.joinBuilder = const HasManyJoinBuilder(),
  });
  final HasManyJoinBuilder joinBuilder;

  String emit({
    required ClassInfo root,
    required Map<String, ClassInfo> classInfos,
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
    final rootPk = pk == null ? '' : ', rootPkColumn: $pk';

    return '''
  ${root.className}Query() : super(_build(), fold$rootPk);

  static Query<Object?> _build() {
${decls.map((d) => '    $d').join('\n')}
    return from(${root.tableMarker}.table)
${joins.map((j) => '        $j').join('\n')};
  }
''';
  }
}
