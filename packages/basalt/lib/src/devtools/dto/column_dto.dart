import 'foreign_key_dto.dart';

/// A table column in the transport model.
final class ColumnDto {
  const ColumnDto({
    required this.name,
    required this.type,
    required this.rawType,
    required this.isNullable,
    required this.isPrimaryKey,
    this.foreignKey,
  });

  factory ColumnDto.fromJson(Map<String, Object?> json) => ColumnDto(
        name: json['name'] as String,
        type: json['type'] as String,
        rawType: json['rawType'] as String,
        isNullable: json['isNullable'] as bool,
        isPrimaryKey: json['isPrimaryKey'] as bool,
        foreignKey: switch (json['foreignKey']) {
          final fk? => ForeignKeyDto.fromJson(fk as Map<String, Object?>),
          _ => null,
        },
      );

  final String name;

  /// Canonical [ColumnType] name (e.g. `integer`, `text`, `dateTime`).
  final String type;
  final String rawType;
  final bool isNullable;
  final bool isPrimaryKey;
  final ForeignKeyDto? foreignKey;

  Map<String, Object?> toJson() => {
        'name': name,
        'type': type,
        'rawType': rawType,
        'isNullable': isNullable,
        'isPrimaryKey': isPrimaryKey,
        if (foreignKey case final fk?) 'foreignKey': fk.toJson(),
      };
}
