import 'column_arg.dart';

/// Emits a `toInsert()` extension on `Iterable<Class>` that builds one
/// multi-row `InsertStatement<Tbl>` (a single `INSERT ... VALUES (...), (...)`)
/// from a list of data-class instances, setting the same writable columns as
/// the single-row emitter. Pure string emit, so it is unit-testable without
/// the analyzer.
final class BatchInsertEmitter {
  const BatchInsertEmitter();

  String emit({
    required String className,
    required String tableMarker,
    required List<ColumnArg> columnArgs,
  }) {
    // `Users.name.set(row.name)` — column accessor on the table marker, value
    // from the iterated instance.
    final values = [
      for (final col in columnArgs)
        if (!col.readOnly)
          '          ${col.columnExpr}.set(row.${col.paramName}),',
    ].join('\n');
    return '''
extension ${className}BatchInsert on Iterable<$className> {
  InsertStatement<$tableMarker> toInsert() {
    final rows = [
      for (final row in this)
        [
$values
        ],
    ];
    if (rows.isEmpty) {
      throw ArgumentError(
          'toInsert() on an empty Iterable<$className>: '
          'an INSERT needs at least one row.');
    }
    return insertInto($tableMarker.table).values(rows);
  }
}
''';
  }
}
