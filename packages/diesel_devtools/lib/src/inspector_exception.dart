/// Raised when the inspector is asked about an unknown instance/table/column.
final class InspectorException implements Exception {
  final String message;
  const InspectorException(this.message);

  @override
  String toString() => 'InspectorException: $message';
}
