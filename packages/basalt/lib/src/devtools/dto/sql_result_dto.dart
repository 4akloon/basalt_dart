import 'json_read.dart';

/// Result of `InspectorService.runSql`: a `read` (columns+rows), a `write`
/// (executed, optional affected count), or an `error`.
final class SqlResultDto {
  const SqlResultDto.read({
    required this.columns,
    required this.rows,
    this.truncated = false,
  })  : affected = null,
        error = null;

  const SqlResultDto.write({this.affected})
      : columns = null,
        rows = null,
        truncated = false,
        error = null;

  const SqlResultDto.error(this.error)
      : columns = null,
        rows = null,
        affected = null,
        truncated = false;

  factory SqlResultDto.fromJson(Map<String, Object?> json) =>
      switch (json['kind']) {
        'read' => SqlResultDto.read(
            columns: asStringList(json['columns']),
            rows: asRows(json['rows']),
            truncated: json['truncated'] == true,
          ),
        'write' => SqlResultDto.write(affected: json['affected'] as int?),
        'error' => SqlResultDto.error(json['error'] as String),
        _ => throw ArgumentError.value(json['kind'], 'json', 'Invalid kind'),
      };

  final List<String>? columns;
  final List<List<Object?>>? rows;
  final int? affected;
  final bool truncated;
  final String? error;

  bool get isError => error != null;
  bool get isRead => columns != null;

  String get kind => error != null
      ? 'error'
      : columns != null
          ? 'read'
          : 'write';

  Map<String, Object?> toJson() => {
        'kind': kind,
        if (columns case final c?) 'columns': c,
        if (rows case final r?) 'rows': r,
        if (affected case final a?) 'affected': a,
        if (truncated) 'truncated': true,
        if (error case final e?) 'error': e,
      };
}
