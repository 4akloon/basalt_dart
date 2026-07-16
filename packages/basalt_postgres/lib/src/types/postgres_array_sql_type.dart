import 'package:basalt/basalt.dart';

import 'postgres_typed_sql_type.dart';

/// Postgres-native array codec for a column of element type [E]
/// (e.g. `integer[]` → `PostgresArraySqlType<int>`, `text[]` →
/// `PostgresArraySqlType<String>`).
///
/// `package:postgres` binds a Dart `List<E>` to the array parameter and returns
/// the column as a `List` of [E], so this codec is a typed pass-through: it
/// forwards the list on encode and casts the driver's list to `List<E>` on
/// decode. Null array elements are not supported (use a non-nullable [E]); wrap
/// the whole codec in `NullableSqlType` for a nullable array *column*.
///
/// Emitted by the postgres adapter's `native_types: true` preset for the common
/// array element types; a schema using it imports `package:basalt_postgres`.
///
/// {@category getting-started}
final class PostgresArraySqlType<E extends Object> extends SqlType<List<E>>
    implements PostgresTypedSqlType {
  const PostgresArraySqlType();

  /// Array type for the common element types; `null` for an element type this
  /// codec has no name for (such a column then can't be cast in `updateAll`).
  @override
  String? get postgresType => switch (E) {
        const (int) => 'bigint[]',
        const (String) => 'text[]',
        const (double) => 'double precision[]',
        const (bool) => 'boolean[]',
        _ => null,
      };

  @override
  Object? encode(List<E> input) => input;

  @override
  List<E> decode(Object? encoded) => switch (encoded) {
        final List<Object?> list => list.cast<E>(),
        _ => throw ArgumentError.value(
            encoded,
            'encoded',
            'Expected a List for an array column',
          ),
      };
}
