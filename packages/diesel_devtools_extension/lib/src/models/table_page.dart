import 'json_rows.dart';

/// One page of table rows.
class TablePage {
  final List<String> columns;
  final List<List<Object?>> rows;
  final int total;
  final int limit;
  final int offset;
  TablePage(this.columns, this.rows, this.total, this.limit, this.offset);

  factory TablePage.fromJson(Map json) => TablePage(
        [for (final c in (json['columns'] as List? ?? const [])) c as String],
        parseRows(json['rows']),
        json['total'] as int? ?? 0,
        json['limit'] as int? ?? 0,
        json['offset'] as int? ?? 0,
      );
}
