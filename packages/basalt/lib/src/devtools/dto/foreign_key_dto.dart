/// A foreign-key target on a column.
final class ForeignKeyDto {
  const ForeignKeyDto(this.table, this.column);
  final String table;
  final String column;

  Map<String, Object?> toJson() => {'table': table, 'column': column};
}
