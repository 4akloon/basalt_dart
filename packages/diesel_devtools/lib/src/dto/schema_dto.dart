import 'table_dto.dart';

/// The schema of one instance.
final class SchemaDto {
  final List<TableDto> tables;
  const SchemaDto(this.tables);

  Map<String, Object?> toJson() =>
      {'tables': [for (final t in tables) t.toJson()]};
}
