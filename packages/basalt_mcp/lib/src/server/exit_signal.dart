import 'dart:async';
import 'dart:io';

/// Waits for SIGINT or SIGTERM to signal graceful shutdown.
final class ExitSignal {
  /// Starts watching for termination signals.
  ExitSignal() {
    if (!Platform.isWindows) {
      _sigtermSubscription =
          ProcessSignal.sigterm.watch().listen(_handleSignal);
    }
    _sigintSubscription = ProcessSignal.sigint.watch().listen(_handleSignal);
  }

  final _completer = Completer<ProcessSignal>();
  StreamSubscription<ProcessSignal>? _sigtermSubscription;
  late final StreamSubscription<ProcessSignal> _sigintSubscription;
  var _disposed = false;

  /// Completes with the first termination signal received.
  Future<ProcessSignal> get wait => _completer.future;

  /// Cancels the signal subscriptions.
  void dispose() => _cleanup();

  void _handleSignal(ProcessSignal signal) {
    if (!_completer.isCompleted) {
      _completer.complete(signal);
      _cleanup();
    }
  }

  void _cleanup() {
    if (_disposed) return;
    _disposed = true;
    _sigtermSubscription?.cancel();
    _sigintSubscription.cancel();
  }
}
