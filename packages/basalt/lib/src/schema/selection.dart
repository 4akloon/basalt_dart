part of 'table.dart';

/// Something selectable in a query's projection — a [TableColumn] or an
/// [Aggregate]. Carries the SQL [selectExpression] to emit, an optional `AS`
/// [selectAlias], the [readKey] a `RowReader` uses to find the value, and the
/// [SqlType] used to decode it.
abstract interface class Selection<T> {
  SqlType<T> get type;
  SqlNode get selectExpression;
  String? get selectAlias;
  String get readKey;
}
