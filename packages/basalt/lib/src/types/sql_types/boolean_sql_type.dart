import '../sql_type.dart';

/// Encodes a canonical Dart `bool`; each dialect's `encodeParam` maps it to
/// the driver form (SQLite: `bool`->`int`). [decode] is lenient so it reads
/// back either representation.
///
/// {@category types}
final class BooleanSqlType extends SqlType<bool> {
  const BooleanSqlType();

  @override
  String get sqlName => 'INTEGER';

  @override
  Object? encode(bool input) => input;

  @override
  bool decode(Object? encoded) =>
      encoded is bool ? encoded : (encoded as num) != 0;
}
