import '../schema/table.dart';

/// Marks a data class for INSERT generation against [table]
/// (e.g. `@Insertable(Users.table)`). The generator emits a `toInsert()`
/// extension method returning an `InsertStatement`, mapping each writable field
/// (everything except `@Column(readOnly: true)`) through `TableColumn.set`.
///
/// Independent of `@Queryable`: a write-only DTO can be `@Insertable` alone.
///
/// {@category annotations}
class Insertable {
  const Insertable(this.table);
  final TableRef table;
}
