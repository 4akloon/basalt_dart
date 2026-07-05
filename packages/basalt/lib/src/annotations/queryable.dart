import '../schema/table.dart';

/// Marks a data class for row-mapper generation against [table]
/// (e.g. `@Queryable(Posts.table)`). The generator emits a `RowMapper<ThisClass>`
/// plus a `fromRow` reader that calls `RowReader.get` for each mapped field.
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
