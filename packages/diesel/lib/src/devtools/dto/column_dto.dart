import 'foreign_key_dto.dart';

/// A table column in the transport model.
final class ColumnDto {
  final String name;

  /// Canonical [ColumnType] name (e.g. `integer`, `text`, `dateTime`).
  final String type;
  final String rawType;
  final bool isNullable;
  final bool isPrimaryKey;
  final ForeignKeyDto? foreignKey;

  const ColumnDto({
    required this.name,
    required this.type,
    required this.rawType,
    required this.isNullable,
    required this.isPrimaryKey,
    this.foreignKey,
  });

  Map<String, Object?> toJson() => {
        'name': name,
        'type': type,
        'rawType': rawType,
        'isNullable': isNullable,
        'isPrimaryKey': isPrimaryKey,
        if (foreignKey case final fk?) 'foreignKey': fk.toJson(),
      };
}
