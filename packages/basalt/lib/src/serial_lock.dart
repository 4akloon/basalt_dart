import 'dart:async';

/// A minimal FIFO async mutex: serializes the [run] callbacks handed to it so
/// that at most one is in flight at a time, in submission order.
///
/// Backends use this to keep transactions from interleaving on a single
/// connection. A statement on a synchronous driver never overlaps another, but a
/// transaction spans multiple `await`s (`BEGIN` … callback … `COMMIT`), and any
/// suspension point would otherwise let a second transaction — or a stray direct
/// write — run against the same connection mid-transaction. Routing the whole
/// transaction through one `SerialLock` makes it hold the connection exclusively
/// from open to commit/rollback; a per-transaction lock likewise serializes
/// sibling nested (`SAVEPOINT`) transactions so their savepoints never overlap.
///
/// {@category connection}
final class SerialLock {
  Future<void> _tail = Future.value();

  /// Runs [action] once all previously submitted actions have completed, and
  /// completes with its result. If [action] throws, the returned future carries
  /// the error but the queue still advances to the next waiter.
  Future<T> run<T>(FutureOr<T> Function() action) {
    final previous = _tail;
    final completer = Completer<void>();
    _tail = completer.future;
    return previous.then((_) => action()).whenComplete(completer.complete);
  }
}
