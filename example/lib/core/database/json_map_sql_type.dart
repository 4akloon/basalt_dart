import 'dart:convert';

import 'package:basalt/basalt.dart';

/// A custom [SqlType] that stores a JSON object (`Map<String, Object?>`) in a
/// `TEXT` column, encoding/decoding with `dart:convert`.
///
/// This is the extension point the `basalt_cli` `types:` config points a column
/// at (see `example/basalt.yaml`): `generate-schema` emits this codec for
/// `products.metadata` instead of a built-in type, and the value round-trips as
/// a real `Map` through reads, writes and predicates. The column is nullable,
/// so the config wraps it as `NullableSqlType(JsonMapSqlType())` — no
/// hand-written `*OrNull` duplicate needed.
///
/// On SQLite the encoded value is a JSON string bound to `TEXT`; the lenient
/// [decode] accepts either a `String` (SQLite) or an already-decoded `Map`
/// (a driver that returns native JSON).
final class JsonMapSqlType extends SqlType<Map<String, Object?>> {
  const JsonMapSqlType();

  @override
  Object? encode(Map<String, Object?> input) => jsonEncode(input);

  @override
  Map<String, Object?> decode(Object? encoded) {
    final decoded = encoded is String ? jsonDecode(encoded) : encoded;
    return (decoded as Map).cast<String, Object?>();
  }
}
