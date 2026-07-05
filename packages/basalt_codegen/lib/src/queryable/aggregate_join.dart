/// One FK join step for an aggregate `@Queryable`.
final class AggregateJoin {
  const AggregateJoin({
    required this.targetMarker,
    required this.fkColumnExpr,
    required this.nullable,
  });
  final String targetMarker;
  final String fkColumnExpr;
  final bool nullable;
}
