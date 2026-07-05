import '../schema/table.dart';

/// Maps a constructor field to a schema [column] and/or tunes its read/write
/// direction. Without it, the field name selects the column by matching the
/// generated schema's camelCase accessor.
///
/// A field can participate in both reading (`@Queryable`) and writing
/// (`@Insertable`/`@AsChangeset`); the flags carve out the exceptions:
/// * [readOnly] — present in SELECT, omitted from INSERT and `UPDATE … SET`
///   (autoincrement primary keys, server-side defaults).
/// * [writeOnly] — omitted from the generated row reader (the field must then be
///   an optional constructor parameter so its default is used), present in writes.
///
/// Setting both flags is a generation error: a field that is neither read nor
/// written is not a column — use a getter for computed values.
///
/// {@category annotations}
class Column {
  const Column(this.column, {this.readOnly = false, this.writeOnly = false});
  final TableColumn column;
  final bool readOnly;
  final bool writeOnly;
}
