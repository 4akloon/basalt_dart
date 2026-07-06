import '../schema/table.dart';

/// Marks a data class for query generation against [table]
/// (e.g. `@Queryable(Posts.table)`). The generator emits a `ThisClassQuery`
/// companion that *is* the canonical query, carrying a `static fromRow`
/// reader (one `RowReader.get` per mapped field) and its `RowMapper`.
///
/// For aggregate views, pass [joins] and optional [orderBy] (private static
/// tear-offs) alongside `@Agg` fields.
///
/// {@category annotations}
class Queryable {
  const Queryable(
    this.table, {
    this.joins = const [],
    this.orderBy,
    this.orderDesc = false,
  });
  final TableRef table;
  final List<Ref> joins;
  final Selection<Object?> Function()? orderBy;
  final bool orderDesc;
}
