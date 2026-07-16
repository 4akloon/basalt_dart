import 'package:basalt/basalt.dart';

/// SQLite: double-quoted identifiers and positional `?` placeholders.
///
/// {@category getting-started}
final class SqliteDialect implements SqlDialect {
  const SqliteDialect();

  @override
  String quoteIdentifier(String name) => '"${name.replaceAll('"', '""')}"';

  @override
  String placeholder(int index) => '?';

  @override
  Object? encodeParam(Object? value) {
    if (value is bool) return value ? 1 : 0;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return value;
  }

  /// SQLite is dynamically typed — parameters never need a `CAST`.
  @override
  String? castType(SqlType<Object?> type) => null;
}
