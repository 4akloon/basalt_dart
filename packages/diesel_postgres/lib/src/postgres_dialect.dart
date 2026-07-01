import 'package:diesel/diesel.dart';

/// Postgres SQL dialect: double-quoted identifiers and numbered `$N` placeholders
/// (1-based), unlike SQLite's positional `?`.
///
/// This is the only dialect-level difference the query serializer needs — proof
/// that the core `QueryBuilder` is truly backend-agnostic. The driver-backed
/// `Connection` will pair this dialect with `package:postgres`.
final class PostgresDialect implements SqlDialect {
  const PostgresDialect();

  @override
  String quoteIdentifier(String name) => '"${name.replaceAll('"', '""')}"';

  @override
  String placeholder(int index) => '\$${index + 1}';
}
