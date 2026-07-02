import 'json_rows.dart';

/// Result of a raw SQL run: `read` (columns+rows), `write`, or `error`.
class SqlResult {
  final String kind;
  final List<String> columns;
  final List<List<Object?>> rows;
  final int? affected;
  final bool truncated;
  final String? error;
  SqlResult({
    required this.kind,
    this.columns = const [],
    this.rows = const [],
    this.affected,
    this.truncated = false,
    this.error,
  });

  factory SqlResult.fromJson(Map json) => SqlResult(
        kind: json['kind'] as String? ?? 'write',
        columns: [
          for (final c in (json['columns'] as List? ?? const [])) c as String
        ],
        rows: parseRows(json['rows']),
        affected: json['affected'] as int?,
        truncated: json['truncated'] as bool? ?? false,
        error: json['error'] as String?,
      );
}
