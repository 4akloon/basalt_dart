import 'aggregate_info.dart';

/// Emits a grouped `MappedQuery` getter for aggregate `@Queryable` classes.
final class AggregateQueryEmitter {
  const AggregateQueryEmitter();

  String emit({
    required String className,
    required String queryName,
    required AggregateInfo info,
  }) {
    final dims = [for (final d in info.dimensions) d.columnExpr].join(', ');
    final aggs =
        [for (final a in info.aggregates) a.selectCall].join(', ');
    final selects = aggs.isEmpty ? dims : '$dims, $aggs';
    final groupBy =
        [for (final d in info.dimensions) d.columnExpr].join(', ');

    final joinLines = StringBuffer();
    for (final j in info.joins) {
      final kind = j.nullable ? 'leftJoin' : 'innerJoin';
      joinLines.writeln(
        '    .$kind(${j.targetMarker}.table, onFk: ${j.fkColumnExpr})',
      );
    }

    final order = info.orderByCall == null
        ? ''
        : '.orderBy(${info.orderByCall}${info.orderDesc ? '.desc()' : '.asc()'})';

    final readerArgs = StringBuffer();
    for (final d in info.dimensions) {
      readerArgs.writeln('          ${d.paramName}: r.get(${d.columnExpr}),');
    }
    for (final a in info.aggregates) {
      final fallback = a.zeroFallback ? ' ?? 0' : '';
      readerArgs.writeln(
        '          ${a.fieldName}: r.get(${a.selectCall})$fallback,',
      );
    }

    return '''
MappedQuery<$className> get $queryName {
  return from(${info.fromMarker}.table)
$joinLines    .select([$selects])
    .groupBy([$groupBy])$order
    .map((r) => $className(
$readerArgs        ));
}
''';
  }
}
