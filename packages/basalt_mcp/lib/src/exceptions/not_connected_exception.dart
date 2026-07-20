/// Thrown when a tool is called without an active VM service connection.
///
/// {@category getting-started}
final class NotConnectedException implements Exception {
  /// Creates the exception.
  const NotConnectedException();

  @override
  String toString() =>
      'Not connected to any app. Use connect first with the VM service URI.';
}
