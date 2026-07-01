import 'column_dto.dart';

/// A table and its columns in the transport model.
final class TableDto {
  final String name;
  final List<ColumnDto> columns;
  const TableDto(this.name, this.columns);

  Map<String, Object?> toJson() =>
      {'name': name, 'columns': [for (final c in columns) c.toJson()]};
}
