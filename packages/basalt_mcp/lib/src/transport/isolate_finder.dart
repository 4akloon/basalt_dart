import 'package:basalt/devtools_client.dart';
import 'package:vm_service/vm_service.dart';

import '../exceptions/vm_service_extension_exception.dart';

/// Locates the isolate that registered the Basalt DevTools inspector.
///
/// A debug app installs the `ext.basalt.*` extensions lazily on the first
/// `BasaltDevTools.register` call, so the finder polls a few times before
/// giving up — the extensions may not be present the instant we connect.
///
/// {@category getting-started}
final class IsolateFinder {
  /// Creates a finder that retries [attempts] times, waiting [delay] between.
  const IsolateFinder({
    this.attempts = 5,
    this.delay = const Duration(milliseconds: 500),
  });

  /// How many times to scan the VM before failing.
  final int attempts;

  /// Delay between scans.
  final Duration delay;

  /// Returns the id of the first isolate exposing the inspector, or throws.
  Future<String> find(VmService service) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(delay);
      if (await _scan(service) case final id?) return id;
    }
    throw VmServiceExtensionException(
      'No isolate found with ${BasaltExtension.listInstances.method}. '
      'Run the app in debug/profile mode and call '
      'BasaltDevTools.register(conn) (see example/lib/main_debug.dart).',
    );
  }

  Future<String?> _scan(VmService service) async {
    final isolates = (await service.getVM()).isolates ?? const [];
    for (final ref in isolates) {
      if (ref.id case final id? when await _hasInspector(service, id)) {
        return id;
      }
    }
    return null;
  }

  Future<bool> _hasInspector(VmService service, String isolateId) async {
    try {
      final isolate = await service.getIsolate(isolateId);
      final rpcs = isolate.extensionRPCs ?? const [];
      return rpcs.contains(BasaltExtension.listInstances.method);
    } catch (_) {
      return false;
    }
  }
}
