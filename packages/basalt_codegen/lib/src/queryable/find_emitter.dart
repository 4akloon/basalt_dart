/// Emits a bare `findX(pkValue)` — the basalt-style find-by-primary-key. It
/// composes the class's query getter with the type-safe `findBy`, so the value
/// type is checked against the PK column (and joins/subset projection are reused).
final class FindEmitter {
  const FindEmitter();

  String emit({
    required String className,
    required String findName,
    required String queryName,
    required String pkColumnExpr,
    required String pkType,
    bool foldQuery = false,
  }) {
    final queryType =
        foldQuery ? 'FoldMappedQuery<$className>' : 'MappedQuery<$className>';
    return '''
/// Fetch the $className with the given primary key.
$queryType $findName($pkType id) =>
    $queryName.findBy($pkColumnExpr, id);
''';
  }
}
