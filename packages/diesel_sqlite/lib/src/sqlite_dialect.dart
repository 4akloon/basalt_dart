import 'package:diesel/diesel.dart';

/// SQLite: double-quoted identifiers and positional `?` placeholders.
final class SqliteDialect implements SqlDialect {
  const SqliteDialect();

  @override
  String quoteIdentifier(String name) => '"${name.replaceAll('"', '""')}"';

  @override
  String placeholder(int index) => '?';
}
