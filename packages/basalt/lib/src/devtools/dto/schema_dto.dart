import 'table_dto.dart';

/// The schema of one instance.
final class SchemaDto {
  const SchemaDto(this.tables);
  final List<TableDto> tables;

  Map<String, Object?> toJson() => {
        'tables': [for (final t in tables) t.toJson()],
      };
}
