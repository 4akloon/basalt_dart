import '../schema/table.dart';

/// Marks a data class for UPDATE generation against [table]
/// (e.g. `@AsChangeset(Users.table)`). The generator emits a `toUpdate()`
/// extension method returning an `UpdateStatement` whose `SET` clause is built
/// from each writable field; the caller appends the `.where(...)` (typically on
/// the primary key). `@Column(readOnly: true)` fields are skipped.
///
/// Independent of `@Queryable`: a class can be `@AsChangeset` alone.
class AsChangeset {
  final TableRef table;
  const AsChangeset(this.table);
}
