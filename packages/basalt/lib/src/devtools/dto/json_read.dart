/// Small coercion helpers for reading `jsonDecode`d wire payloads into DTOs.
///
/// `jsonDecode` produces `List<dynamic>` / `Map<String, dynamic>`, so a blind
/// `as List<String>` / `as List<List<Object?>>` cast throws. These helpers
/// rebuild the nested collections with the element types the DTOs expect.
library;

/// Coerces a decoded JSON value into `List<String>`.
List<String> asStringList(Object? value) =>
    [for (final e in value as List) e as String];

/// Coerces a decoded JSON value into a list of row lists.
List<List<Object?>> asRows(Object? value) => [
      for (final row in value as List) [...row as List]
    ];
