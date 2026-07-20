import 'package:basalt/devtools_client.dart';

/// UI-facing convenience accessors on a [TableDto].
extension TableDtoX on TableDto {
  /// Names of the primary-key columns.
  Set<String> get primaryKeys => {
    for (final c in columns)
      if (c.isPrimaryKey) c.name,
  };
}
