/// One FK join step for an aggregate `@Queryable`.
final class AggregateJoin {
  const AggregateJoin({
    required this.parentMarker,
    required this.targetMarker,
    required this.fkColumnExpr,
    required this.nullable,
  });

  /// Table that owns the FK column (`Ref<_, Tbl, _>` → `Tbl`).
  final String parentMarker;

  /// Table referenced by the FK (`Ref<_, _, RefTbl>` → `RefTbl`).
  final String targetMarker;
  final String fkColumnExpr;
  final bool nullable;
}
