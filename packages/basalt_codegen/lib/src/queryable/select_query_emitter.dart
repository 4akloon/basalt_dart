import 'column_arg.dart';

/// Emits the constructor + `_build()` members of a `${Class}Query` companion
/// for a `@Queryable` class that has no relations: the query selects exactly
/// the class's readable columns (a column *subset* of the table) and decodes
/// them with `fromRow`. This is the "Selectable" analog — projecting a chosen
/// set of columns into a lightweight view class, so `db.fetch(UserQuery())`
/// reads only those columns instead of `SELECT *`.
final class SelectQueryEmitter {
  const SelectQueryEmitter();

  String emit({
    required String className,
    required String tableMarker,
    required List<ColumnArg> columnArgs,
  }) {
    final cols = [
      for (final c in columnArgs)
        if (!c.writeOnly) c.columnExpr
    ].join(', ');
    return '''
  ${className}Query() : super(_build(), fromRow);

  static Query<$tableMarker> _build() =>
      from($tableMarker.table).select([$cols]);
''';
  }
}
