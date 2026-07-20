/// Raised when the inspector is asked about an unknown instance/table/column.
final class InspectorException implements Exception {
  const InspectorException(this.message);
  final String message;

  @override
  String toString() => 'InspectorException: $message';
}
