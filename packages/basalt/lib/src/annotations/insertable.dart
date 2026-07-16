import '../schema/table.dart';

/// Marks a data class for INSERT generation against [table]
/// (e.g. `@Insertable(Users.table)`). The generator emits two `toInsert()`
/// extension methods returning an `InsertStatement`, mapping each writable
/// field (everything except `@Column(readOnly: true)`) through
/// `TableColumn.set`: one on the class itself (single-row insert) and one on
/// `Iterable` of it, which batches every element into a single multi-row
/// `INSERT ... VALUES (...), (...)`.
///
/// Independent of `@Queryable`: a write-only DTO can be `@Insertable` alone.
///
/// {@category annotations}
class Insertable {
  const Insertable(this.table);
  final TableRef table;
}
