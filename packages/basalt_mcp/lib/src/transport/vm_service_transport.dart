import 'package:basalt/devtools_client.dart';
import 'package:logging/logging.dart' as logging;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../exceptions/not_connected_exception.dart';
import '../exceptions/vm_service_extension_exception.dart';
import 'isolate_finder.dart';

/// [InspectorTransport] backed by a `package:vm_service` connection.
///
/// Owns the connection lifecycle to a running debug app and forwards
/// `ext.basalt.*` calls to the isolate that registered the inspector. The
/// concrete VM service dependency lives here so the shared [InspectorClient]
/// stays transport-agnostic.
///
/// {@category getting-started}
final class VmServiceTransport implements InspectorTransport {
  /// Creates a transport, optionally overriding the [IsolateFinder] (tests).
  VmServiceTransport({IsolateFinder finder = const IsolateFinder()})
      : _finder = finder,
        _logger = logging.Logger('VmServiceTransport');

  final IsolateFinder _finder;
  final logging.Logger _logger;
  VmService? _service;
  String? _isolateId;

  /// Whether a connection with a Basalt isolate is active.
  bool get isConnected => _service != null && _isolateId != null;

  /// Connects to [uri] and locates the isolate exposing the inspector.
  Future<void> connect(String uri) async {
    if (isConnected) await disconnect();
    _logger.info('Connecting to VM service at $uri');
    try {
      final service = await vmServiceConnectUri(uri);
      _service = service;
      _isolateId = await _finder.find(service);
      _logger.info('Connected to isolate: $_isolateId');
    } catch (err) {
      _logger.severe('Failed to connect to VM service', err);
      await disconnect();
      rethrow;
    }
  }

  /// Tears down the connection, if any.
  Future<void> disconnect() async {
    if (_service case final service?) {
      _logger.info('Disconnecting from VM service');
      await service.dispose();
    }
    _service = null;
    _isolateId = null;
  }

  @override
  Future<Map<String, Object?>> call(String method, Map<String, String> args) {
    final service = _service;
    final isolateId = _isolateId;
    if (service == null || isolateId == null) {
      throw const NotConnectedException();
    }
    return _invoke(service, isolateId, method, args);
  }

  Future<Map<String, Object?>> _invoke(
    VmService service,
    String isolateId,
    String method,
    Map<String, String> args,
  ) async {
    _logger.fine('Calling $method with $args');
    try {
      final response = await service.callServiceExtension(
        method,
        isolateId: isolateId,
        args: args,
      );
      final json = response.json;
      if (json == null) {
        throw VmServiceExtensionException('$method returned a null response');
      }
      return json.cast<String, Object?>();
    } on RPCError catch (e) {
      _logger.severe('Error calling $method', e);
      throw VmServiceExtensionException(
        '$method failed',
        errorCode: e.code,
        stackTrace: e.message,
      );
    }
  }
}
