import 'dart:convert';

import 'package:basalt/basalt.dart';

/// A custom [SqlType] that stores a JSON object (`Map<String, Object?>`) in a
/// `TEXT` column, encoding/decoding with `dart:convert`.
///
/// This is the extension point the `basalt_cli` `types:` config points a column
/// at (see `example/basalt.yaml`): `generate-schema` emits this codec for
/// `products.metadata` instead of a built-in type, and the value round-trips as
/// a real `Map` through reads, writes and predicates.
///
/// On SQLite the encoded value is a JSON string bound to `TEXT`; the lenient
/// [decode] accepts either a `String` (SQLite) or an already-decoded `Map`
/// (a driver that returns native JSON).
final class JsonMapOrNullSqlType extends SqlType<Map<String, Object?>?> {
  const JsonMapOrNullSqlType();

  @override
  String get sqlName => 'TEXT';

  @override
  Object? encode(Map<String, Object?>? input) =>
      input == null ? null : jsonEncode(input);

  @override
  Map<String, Object?>? decode(Object? encoded) {
    if (encoded == null) return null;
    final decoded = encoded is String ? jsonDecode(encoded) : encoded;
    return (decoded as Map).cast<String, Object?>();
  }
}
