import 'json_read.dart';

/// One page of table rows.
final class TablePageDto {
  const TablePageDto({
    required this.columns,
    required this.rows,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TablePageDto.fromJson(Map<String, Object?> json) => TablePageDto(
        columns: asStringList(json['columns']),
        rows: asRows(json['rows']),
        total: json['total'] as int,
        limit: json['limit'] as int,
        offset: json['offset'] as int,
      );

  final List<String> columns;
  final List<List<Object?>> rows;
  final int total;
  final int limit;
  final int offset;

  Map<String, Object?> toJson() => {
        'columns': columns,
        'rows': rows,
        'total': total,
        'limit': limit,
        'offset': offset,
      };
}
