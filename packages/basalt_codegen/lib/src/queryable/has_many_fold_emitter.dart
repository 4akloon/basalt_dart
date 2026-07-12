import 'class_info.dart';
import 'has_many_edge.dart';
import 'require_present.dart';

/// Emitted `@HasMany` fold code: the `static fold` member of the `${Class}Query`
/// companion plus the top-level private `_ClassFoldAcc` accumulator classes it
/// uses (private helpers can't nest inside the companion — Dart has no nested
/// classes).
typedef HasManyFoldCode = ({String foldMember, List<String> accClasses});

/// Emits `static List<Class> fold(List<RowReader>)` and the nested
/// `_ClassFoldAcc` helper classes.
final class HasManyFoldEmitter {
  const HasManyFoldEmitter();

  HasManyFoldCode emit({
    required ClassInfo root,
    required Map<String, ClassInfo> classInfos,
  }) {
    final accClasses = <String>[];
    final emitted = <String>{};

    void ensureAcc(ClassInfo info) {
      if (info.hasManyEdges.isEmpty) return;
      final name = '_${info.className}FoldAcc';
      if (!emitted.add(name)) return;
      accClasses.add(_emitAccClass(info, classInfos));
      for (final edge in info.hasManyEdges) {
        final child = classInfos[edge.childClass];
        if (child != null) ensureAcc(child);
      }
    }

    ensureAcc(root);
    return (foldMember: _emitFoldFn(root, classInfos), accClasses: accClasses);
  }

  String _emitAccClass(
    ClassInfo info,
    Map<String, ClassInfo> classInfos,
  ) {
    final buf = StringBuffer()
      ..writeln('final class _${info.className}FoldAcc {')
      ..writeln('  _${info.className}FoldAcc(this.base);')
      ..writeln('  final ${info.className} base;');

    for (final edge in info.hasManyEdges) {
      final child = requirePresent(
        classInfos[edge.childClass],
        'the registered ClassInfo for ${edge.childClass}',
      );
      final childType = child.hasManyEdges.isNotEmpty
          ? '_${child.className}FoldAcc'
          : child.className;
      buf.writeln('  final ${edge.fieldName} = <int, $childType>{};');
    }

    buf
      ..writeln()
      ..writeln('  ${info.className} build() => ${info.className}(');

    for (final col in info.columnArgs) {
      if (!col.writeOnly) {
        buf.writeln('    ${col.paramName}: base.${col.paramName},');
      }
    }
    for (final rel in info.ownEdges) {
      buf.writeln('    ${rel.fieldName}: base.${rel.fieldName},');
    }
    for (final edge in info.hasManyEdges) {
      final child = requirePresent(
        classInfos[edge.childClass],
        'the registered ClassInfo for ${edge.childClass}',
      );
      if (child.hasManyEdges.isNotEmpty) {
        buf.writeln(
          '    ${edge.fieldName}: [for (final c in ${edge.fieldName}.values) c.build()],',
        );
      } else {
        buf.writeln(
          '    ${edge.fieldName}: [for (final c in ${edge.fieldName}.values) c],',
        );
      }
    }

    buf
      ..writeln('  );')
      ..writeln('}');
    return buf.toString();
  }

  String _emitFoldFn(ClassInfo root, Map<String, ClassInfo> classInfos) {
    final pkType = root.pkType ?? 'Object';
    final pkExpr =
        requirePresent(root.pkColumnExpr, 'the root primary-key column');
    final relationBudget = root.ownEdges.isEmpty
        ? 0
        : root.ownEdges.map((e) => e.depth).reduce((a, b) => a > b ? a : b);

    final buf = StringBuffer()
      ..writeln('  /// Folds flat JOIN rows into deduplicated parents.')
      ..writeln('  static List<${root.className}> fold(')
      ..writeln('    List<RowReader> rows,')
      ..writeln('  ) {')
      ..writeln('    final parents = <$pkType, _${root.className}FoldAcc>{};')
      ..writeln('    for (final r in rows) {')
      ..writeln('      final pk = r.get($pkExpr);')
      ..writeln(
        '      final acc = parents.putIfAbsent(pk, () => _${root.className}FoldAcc(',
      );

    if (root.ownEdges.isNotEmpty) {
      buf.writeln(
        '        fromRow(r, ${root.tableMarker}.table, \'\', $relationBudget),',
      );
    } else {
      buf.writeln('        ${root.className}(');
      for (final col in root.columnArgs) {
        if (!col.writeOnly) {
          buf.writeln('          ${col.paramName}: r.get(${col.columnExpr}),');
        }
      }
      buf.writeln('        ),');
    }

    buf.writeln('      ));');

    for (final edge in root.hasManyEdges) {
      buf.write(_mergeHasMany(edge, edge.fieldName, 'acc', classInfos));
    }

    buf
      ..writeln('    }')
      ..writeln('    return [for (final a in parents.values) a.build()];')
      ..writeln('  }');
    return buf.toString();
  }

  String _mergeHasMany(
    HasManyEdge edge,
    String aliasPath,
    String parentAccVar,
    Map<String, ClassInfo> classInfos,
  ) {
    final child = requirePresent(
      classInfos[edge.childClass],
      'the registered ClassInfo for ${edge.childClass}',
    );
    final childPk =
        requirePresent(child.pkColumnExpr, 'the child primary-key column');
    final src = '${child.tableMarker}.table.aliased(\'$aliasPath\')';
    final childPkSel = '$src.col($childPk)';
    final reader = '${child.className}Query.fromRow';
    final budget = child.ownEdges.isEmpty
        ? 0
        : child.ownEdges.map((e) => e.depth).reduce((a, b) => a > b ? a : b);
    final prefix = '${aliasPath}_';
    final readerCall = budget == 0
        ? '$reader(r, $src)'
        : '$reader(r, $src, \'$prefix\', $budget,)';

    final buf = StringBuffer()
      ..writeln('      if (r.isPresent($childPkSel)) {')
      ..writeln('        final childPk = r.get($childPkSel);');

    if (child.hasManyEdges.isNotEmpty) {
      buf.writeln(
        '        final childAcc = $parentAccVar.${edge.fieldName}'
        '.putIfAbsent(childPk, () => _${child.className}FoldAcc($readerCall));',
      );
      for (final nested in child.hasManyEdges) {
        buf.write(
          _mergeHasMany(
            nested,
            '${aliasPath}_${nested.fieldName}',
            'childAcc',
            classInfos,
          ),
        );
      }
    } else {
      buf.writeln(
        '        $parentAccVar.${edge.fieldName}.putIfAbsent(childPk, () => $readerCall);',
      );
    }

    buf.writeln('      }');
    return buf.toString();
  }
}
