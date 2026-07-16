import 'package:basalt/basalt.dart';

import 'types/postgres_typed_sql_type.dart';

/// Postgres SQL dialect: double-quoted identifiers, numbered `$N` placeholders
/// (1-based, unlike SQLite's positional `?`), and parameter casts for the
/// contexts where the server can't infer a type (batch `updateAll`).
///
/// These are the only dialect-level differences the query serializer needs —
/// proof that the core `QueryBuilder` is truly backend-agnostic. The
/// driver-backed `Connection` pairs this dialect with `package:postgres`.
///
/// {@category getting-started}
final class PostgresDialect implements SqlDialect {
  const PostgresDialect();

  @override
  String quoteIdentifier(String name) => '"${name.replaceAll('"', '""')}"';

  @override
  String placeholder(int index) => '\$${index + 1}';

  /// Postgres binds `bool` and `DateTime` natively, so canonical values pass
  /// through unchanged.
  @override
  Object? encodeParam(Object? value) => value;

  /// Native type name for [type], so `updateAll`'s `VALUES` parameters stay
  /// preparable: a custom codec implementing [PostgresTypedSqlType] names
  /// itself, the core types map to their canonical Postgres types, and
  /// `NullableSqlType` unwraps to its inner codec. Unknown custom types get no
  /// cast (`null`) — implement [PostgresTypedSqlType] to opt in.
  @override
  String? castType(SqlType<Object?> type) {
    var base = type;
    while (base is NullableSqlType) {
      base = base.inner;
    }
    return switch (base) {
      final PostgresTypedSqlType typed => typed.postgresType,
      IntSqlType() => 'bigint',
      StringSqlType() => 'text',
      BooleanSqlType() => 'boolean',
      DoubleSqlType() => 'double precision',
      DateTimeSqlType() => 'timestamptz',
      BlobSqlType() => 'bytea',
      _ => null,
    };
  }
}
