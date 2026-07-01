/// Coerces the JSON `rows` payload (a list of lists) into typed rows.
List<List<Object?>> parseRows(Object? raw) => [
      for (final row in (raw as List? ?? const []))
        [for (final cell in (row as List)) cell],
    ];
