import 'column_dto.dart';

/// A table and its columns in the transport model.
final class TableDto {
  const TableDto(this.name, this.columns);

  factory TableDto.fromJson(Map<String, Object?> json) => TableDto(
        json['name'] as String,
        (json['columns'] as List<Object?>)
            .map((c) => ColumnDto.fromJson(c as Map<String, Object?>))
            .toList(),
      );

  final String name;
  final List<ColumnDto> columns;

  Map<String, Object?> toJson() => {
        'name': name,
        'columns': [for (final c in columns) c.toJson()],
      };
}
