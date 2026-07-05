import 'column_arg.dart';

/// Emits a select-narrowing query getter for a `@Queryable` class that has no
/// relations: `xQuery` selects exactly the class's readable columns (a column
/// *subset* of the table) and maps them. This is the "Selectable" analog —
/// projecting a chosen set of columns into a lightweight view class, so
/// `db.fetch(userSummaryQuery)` reads only those columns instead of `SELECT *`.
final class SelectQueryEmitter {
  const SelectQueryEmitter();

  String emit({
    required String className,
    required String queryName,
    required String tableMarker,
    required String readerName,
    required List<ColumnArg> columnArgs,
  }) {
    final cols =
        [for (final c in columnArgs) if (!c.writeOnly) c.columnExpr].join(', ');
    return '''
MappedQuery<$className> get $queryName =>
    from($tableMarker.table).select([$cols]).map($readerName);
''';
  }
}
