/// Invokes a `ext.basalt.*` service extension and returns its decoded JSON body.
///
/// This is the seam between the transport-agnostic [InspectorClient] and the
/// concrete VM service connection. Each consumer supplies its own transport —
/// the DevTools extension over the shell's `serviceManager`, the MCP server over
/// `package:vm_service` — which keeps those platform dependencies (and
/// `dart:io`) out of the core package.
abstract interface class InspectorTransport {
  /// Calls [method] (a [BasaltExtension.method] value) with string-valued [args]
  /// and returns the decoded response map.
  Future<Map<String, Object?>> call(String method, Map<String, String> args);
}
