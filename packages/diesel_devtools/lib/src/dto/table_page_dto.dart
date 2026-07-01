/// One page of table rows.
final class TablePageDto {
  final List<String> columns;
  final List<List<Object?>> rows;
  final int total;
  final int limit;
  final int offset;

  const TablePageDto({
    required this.columns,
    required this.rows,
    required this.total,
    required this.limit,
    required this.offset,
  });

  Map<String, Object?> toJson() => {
        'columns': columns,
        'rows': rows,
        'total': total,
        'limit': limit,
        'offset': offset,
      };
}
