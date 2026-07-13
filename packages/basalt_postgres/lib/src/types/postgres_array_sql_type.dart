import 'package:basalt/basalt.dart';

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
final class PostgresArraySqlType<E extends Object> extends SqlType<List<E>> {
  const PostgresArraySqlType();

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
