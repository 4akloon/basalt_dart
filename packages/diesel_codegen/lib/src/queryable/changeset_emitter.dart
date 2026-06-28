import 'column_arg.dart';

/// Emits a `toUpdate()` extension that builds an `UpdateStatement<Tbl>` whose
/// `SET` clause covers every writable column (everything except
/// `@Column(readOnly: true)`); the caller appends `.where(...)`, typically on
/// the primary key. Pure string emit, so it is unit-testable without the analyzer.
final class ChangesetEmitter {
  const ChangesetEmitter();

  String emit({
    required String className,
    required String tableMarker,
    required List<ColumnArg> columnArgs,
  }) {
    final sets = [
      for (final col in columnArgs)
        if (!col.readOnly) '      .value(${col.columnExpr}.set(${col.paramName}))',
    ].join('\n');
    return '''
extension ${className}Changeset on $className {
  UpdateStatement<$tableMarker> toUpdate() => update($tableMarker.table)
$sets;
}
''';
  }
}
