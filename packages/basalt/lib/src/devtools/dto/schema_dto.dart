import 'table_dto.dart';

/// The schema of one instance.
final class SchemaDto {
  const SchemaDto(this.tables);

  factory SchemaDto.fromJson(Map<String, Object?> json) => SchemaDto(
        (json['tables'] as List<Object?>)
            .map((t) => TableDto.fromJson(t as Map<String, Object?>))
            .toList(),
      );

  final List<TableDto> tables;

  Map<String, Object?> toJson() => {
        'tables': [for (final t in tables) t.toJson()],
      };
}
