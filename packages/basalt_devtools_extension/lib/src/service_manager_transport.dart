import 'package:basalt/devtools_client.dart';
import 'package:devtools_extensions/devtools_extensions.dart';

/// [InspectorTransport] backed by the DevTools shell's `serviceManager`.
///
/// The shell owns the VM service connection and auto-targets the main isolate,
/// so this just forwards each `ext.basalt.*` call and returns its JSON body.
final class ServiceManagerTransport implements InspectorTransport {
  /// Creates the transport.
  const ServiceManagerTransport();

  @override
  Future<Map<String, Object?>> call(
    String method,
    Map<String, String> args,
  ) async {
    final response = await serviceManager.callServiceExtensionOnMainIsolate(
      method,
      args: args,
    );
    return response.json ?? const {};
  }
}
