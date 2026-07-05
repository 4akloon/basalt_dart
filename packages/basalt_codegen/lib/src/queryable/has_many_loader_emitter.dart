import 'class_info.dart';
import 'has_many_edge.dart';
import 'naming.dart';

/// Emits batched async loaders for `@HasMany` collections (no N+1).
final class HasManyLoaderEmitter {
  const HasManyLoaderEmitter();

  String emit({
    required ClassInfo info,
    required Map<String, ClassInfo> classInfos,
  }) {
    final cn = info.className;
    final qn = '${lowerFirst(cn)}Query';
    final pk = info.pkParamName;
    if (pk == null) {
      throw StateError('load$cn requires a primary-key field on $cn.');
    }

    final buf = StringBuffer()
      ..writeln('Future<List<$cn>> load$cn(')
      ..writeln('  Connection db, {')
      ..writeln('  MappedQuery<$cn>? query,')
      ..writeln('}) async {')
      ..writeln('  final base = await (query ?? $qn).load(db);')
      ..writeln('  if (base.isEmpty) return base;')
      ..writeln('  final keys = [for (final row in base) row.$pk];');

    for (final edge in info.hasManyEdges) {
      final grouped = '${edge.fieldName}ByParent';
      final rowsVar = '${edge.fieldName}Rows';
      final childQuery = '${lowerFirst(edge.childClass)}Query';
      final childInfo = classInfos[edge.childClass];
      final childHasMany =
          (childInfo?.hasManyEdges ?? const <HasManyEdge>[]).isNotEmpty;

      buf
        ..writeln('  final $grouped = {')
        ..writeln('    for (final k in keys) k: <${edge.childClass}>[],')
        ..writeln('  };');

      if (childHasMany) {
        buf.writeln(
          '  final $rowsVar = await load${edge.childClass}(db, '
          'query: $childQuery.where(${edge.childFkColumnExpr}.isIn(keys)),);',
        );
      } else {
        buf.writeln(
          '  final $rowsVar = await $childQuery'
          '.where(${edge.childFkColumnExpr}.isIn(keys)).load(db);',
        );
      }

      buf
        ..writeln('  for (final row in $rowsVar) {')
        ..writeln(
          '    ($grouped[row.${edge.childFkParamName}] ??= []).add(row);',
        )
        ..writeln('  }');
    }

    buf
      ..writeln('  return [')
      ..writeln('    for (final row in base)')
      ..writeln('      $cn(');

    for (final col in info.columnArgs) {
      if (!col.writeOnly) {
        buf.writeln('        ${col.paramName}: row.${col.paramName},');
      }
    }
    for (final rel in info.ownEdges) {
      buf.writeln('        ${rel.fieldName}: row.${rel.fieldName},');
    }
    for (final edge in info.hasManyEdges) {
      buf.writeln(
        '        ${edge.fieldName}: ${edge.fieldName}ByParent[row.$pk] '
        '?? const [],',
      );
    }

    buf
      ..writeln('      ),')
      ..writeln('  ];')
      ..writeln('}');

    if (info.pkColumnExpr case final pkExpr? when info.pkType != null) {
      buf
        ..writeln()
        ..writeln('Future<$cn?> find${cn}ById(Connection db, ${info.pkType} id) async {')
        ..writeln('  final rows = await load$cn(db, query: $qn.findBy($pkExpr, id));')
        ..writeln('  return rows.isEmpty ? null : rows.single;')
        ..writeln('}');
    }

    return buf.toString();
  }
}
