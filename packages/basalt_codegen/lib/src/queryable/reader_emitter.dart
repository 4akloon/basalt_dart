import 'column_arg.dart';
import 'relation_arg.dart';

/// Emits the public, alias-parameterized `static fromRow` reader member of the
/// generated `${Class}Query` companion.
///
/// The reader is public (and static) on purpose: relation targets living in
/// other libraries reuse it as `TargetQuery.fromRow` through a normal import
/// instead of every consumer regenerating a private copy — and without
/// instantiating a whole query object just to read one row. Relations are
/// expanded at runtime via the `budget` parameter, so one reader covers every
/// join depth.
final class ReaderEmitter {
  const ReaderEmitter();

  String emit({
    required String className,
    required String tableMarker,
    required List<ColumnArg> columnArgs,
    required List<RelationArg> relationArgs,
  }) {
    // `prefix`/`budget` only exist when the class actually has relations to
    // unroll; leaf readers stay a simple `(r, [src])`.
    final hasRelations = relationArgs.isNotEmpty;
    final optionals = <String>[
      'QuerySource<$tableMarker> src = $tableMarker.table',
      if (hasRelations) "String prefix = ''",
      if (hasRelations) 'int budget = 0',
    ];
    final params = 'RowReader r, [${optionals.join(', ')},]';

    final args = <String>[
      for (final col in columnArgs)
        if (!col.writeOnly)
          col.isNamed
              ? '${col.paramName}: r.get(src.col(${col.columnExpr}))'
              : 'r.get(src.col(${col.columnExpr}))',
      for (final rel in relationArgs) '${rel.fieldName}: ${rel.childCall}',
    ];
    final body = args.map((a) => '        $a,').join('\n');
    return '''
  /// Reads a [$className] from [r] at [src] (alias-aware, composable).
  static $className fromRow($params) => $className(
$body
      );
''';
  }
}
