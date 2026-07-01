/// A foreign-key target on a column.
final class ForeignKeyDto {
  final String table;
  final String column;
  const ForeignKeyDto(this.table, this.column);

  Map<String, Object?> toJson() => {'table': table, 'column': column};
}
