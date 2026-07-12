import 'aggregate_info.dart';

/// Emits the members of a `${Class}Query` companion for an aggregate
/// (GROUP BY) `@Queryable` class.
///
/// Each `@Agg` tear-off is hoisted into one `static final` field shared by the
/// SELECT projection, the ORDER BY and the row decoder — the same `Aggregate`
/// instance is selected and read back (by its `readKey` alias), instead of
/// re-invoking the user's static per clause.
final class AggregateQueryEmitter {
  const AggregateQueryEmitter();

  String emit({
    required String className,
    required AggregateInfo info,
  }) {
    // Hoist every @Agg tear-off call into a static final field.
    final fieldOf = <String, String>{};
    final aggFields = StringBuffer();
    for (final a in info.aggregates) {
      final field = '_${a.fieldName}';
      fieldOf[a.selectCall] = field;
      aggFields.writeln('  static final $field = ${a.selectCall};');
    }

    final dims = [for (final d in info.dimensions) d.columnExpr].join(', ');
    final aggs =
        [for (final a in info.aggregates) fieldOf[a.selectCall]].join(', ');
    final selects = aggs.isEmpty ? dims : '$dims, $aggs';
    final groupBy = [for (final d in info.dimensions) d.columnExpr].join(', ');

    final joinLines = StringBuffer();
    final tablesInScope = {info.fromMarker};
    for (final j in info.joins) {
      final joinMarker = tablesInScope.contains(j.parentMarker)
          ? j.targetMarker
          : j.parentMarker;
      tablesInScope.add(joinMarker);
      final kind = j.nullable ? 'leftJoin' : 'innerJoin';
      joinLines.writeln(
        '        .$kind($joinMarker.table, onFk: ${j.fkColumnExpr})',
      );
    }

    // ORDER BY reuses the aggregate's field when it points at the same
    // tear-off; a distinct tear-off gets its own hoisted field.
    var orderFieldDecl = '';
    var order = '';
    if (info.orderByCall case final call?) {
      final orderField = fieldOf[call] ?? '_orderKey';
      if (!fieldOf.containsKey(call)) {
        orderFieldDecl = '  static final $orderField = $call;\n';
      }
      order =
          '\n        .orderBy($orderField${info.orderDesc ? '.desc()' : '.asc()'})';
    }

    final readerArgs = StringBuffer();
    for (final d in info.dimensions) {
      readerArgs.writeln('        ${d.paramName}: r.get(${d.columnExpr}),');
    }
    for (final a in info.aggregates) {
      final fallback = a.zeroFallback ? ' ?? 0' : '';
      readerArgs.writeln(
        '        ${a.fieldName}: r.get(${fieldOf[a.selectCall]})$fallback,',
      );
    }

    return '''
  ${className}Query() : super(_build(), _decode);

$aggFields$orderFieldDecl
  static Query<Object?> _build() => from(${info.fromMarker}.table)
$joinLines        .select([$selects])
        .groupBy([$groupBy])$order;

  static $className _decode(RowReader r) => $className(
$readerArgs      );
''';
  }
}
