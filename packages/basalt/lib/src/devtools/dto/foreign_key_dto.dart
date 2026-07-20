/// A foreign-key target on a column.
final class ForeignKeyDto {
  const ForeignKeyDto(this.table, this.column);

  factory ForeignKeyDto.fromJson(Map<String, Object?> json) => ForeignKeyDto(
        json['table'] as String,
        json['column'] as String,
      );

  final String table;
  final String column;

  Map<String, Object?> toJson() => {
        'table': table,
        'column': column,
      };
}
