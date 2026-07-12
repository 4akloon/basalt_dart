import 'column_arg.dart';

/// Emits a `toInsert()` extension that builds an `InsertStatement<Tbl>` from a
/// data class instance, setting every writable column (everything except
/// `@Column(readOnly: true)`) via `TableColumn.set`. Pure string emit, so it is
/// unit-testable without the analyzer.
final class InsertEmitter {
  const InsertEmitter();

  String emit({
    required String className,
    required String tableMarker,
    required List<ColumnArg> columnArgs,
  }) {
    // `Users.name.set(name)` — column accessor on the table marker, value from
    // the in-scope instance field.
    final values = [
      for (final col in columnArgs)
        if (!col.readOnly)
          '      .value(${col.columnExpr}.set(${col.paramName}))',
    ].join('\n');
    return '''
extension ${className}Insert on $className {
  InsertStatement<$tableMarker> toInsert() => insertInto($tableMarker.table)
$values;
}
''';
  }
}
