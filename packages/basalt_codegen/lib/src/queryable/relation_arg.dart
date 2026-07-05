/// A nested relation argument inlined into a unified reader.
final class RelationArg {
  const RelationArg({required this.fieldName, required this.childCall});
  final String fieldName;
  final String childCall;
}
