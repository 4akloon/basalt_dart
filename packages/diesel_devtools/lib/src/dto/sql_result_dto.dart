/// Result of `InspectorService.runSql`: a `read` (columns+rows), a `write`
/// (executed, optional affected count), or an `error`.
final class SqlResultDto {
  final List<String>? columns;
  final List<List<Object?>>? rows;
  final int? affected;
  final bool truncated;
  final String? error;

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
