/// Thrown when an `ext.basalt.*` VM service extension call fails.
///
/// {@category getting-started}
final class VmServiceExtensionException implements Exception {
  /// Creates the exception with a [message] and optional diagnostics.
  VmServiceExtensionException(this.message, {this.errorCode, this.stackTrace});

  /// Human-readable description of the failure.
  final String message;

  /// VM service RPC error code, when the failure came from an `RPCError`.
  final int? errorCode;

  /// Server-side stack trace, when one was reported.
  final String? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (stackTrace case final trace?) {
      buffer.write('\nStack trace: $trace');
    }
    return buffer.toString();
  }
}
