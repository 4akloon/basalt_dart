import 'package:basalt/basalt.dart';

/// Accumulates bound parameters for one raw statement, delegating placeholder
/// syntax and value encoding entirely to the connection's [SqlDialect]. This is
/// what keeps the inspector free of any dialect-specific SQL knowledge.
final class ParamBinder {
  /// Creates a binder that emits placeholders and encodes values with [dialect].
  ParamBinder(this.dialect);

  /// Dialect that governs placeholders, identifier quoting, and value encoding.
  final SqlDialect dialect;

  /// The bound parameters accumulated so far, in placeholder order.
  final List<Object?> params = [];

  /// Encodes and stores [value], returning its positional placeholder.
  String bind(Object? value) {
    params.add(dialect.encodeParam(value));
    return dialect.placeholder(params.length - 1);
  }
}
