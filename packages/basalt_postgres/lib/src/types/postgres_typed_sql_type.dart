/// A `SqlType` that knows its native Postgres type name.
///
/// `PostgresDialect.castType` consults this first, so any custom codec that
/// implements it becomes usable where basalt must cast bound parameters — the
/// `VALUES` table of a batch `updateAll`, whose parameter types Postgres
/// cannot otherwise infer:
///
/// ```dart
/// final class PointSqlType extends SqlType<Point>
///     implements PostgresTypedSqlType {
///   @override
///   String? get postgresType => 'point';
///   // encode/decode ...
/// }
/// ```
///
/// The four native codecs shipped by this package (`PostgresJsonbSqlType`,
/// `PostgresUuidSqlType`, `PostgresNumericSqlType`, `PostgresArraySqlType`)
/// implement it; the core types (`IntSqlType`, `StringSqlType`, ...) are
/// mapped directly by the dialect.
///
/// {@category getting-started}
abstract interface class PostgresTypedSqlType {
  /// The native type name to `CAST` to, or `null` when no cast is available
  /// (the value then only works where Postgres can infer its type).
  String? get postgresType;
}
