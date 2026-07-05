/// A `@HasMany` edge extracted from a constructor parameter.
final class HasManyEdge {
  const HasManyEdge({
    required this.fieldName,
    required this.childClass,
    required this.childMarker,
    required this.childFkColumnExpr,
    required this.childFkParamName,
    required this.parentPkColumnExpr,
    required this.parentPkParamName,
  });
  final String fieldName;
  final String childClass;
  final String childMarker;
  final String childFkColumnExpr;
  final String childFkParamName;
  final String parentPkColumnExpr;
  final String parentPkParamName;
}
