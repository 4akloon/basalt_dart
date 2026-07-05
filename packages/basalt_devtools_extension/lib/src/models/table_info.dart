import 'column_info.dart';

/// A table and its columns.
class TableInfo {
  final String name;
  final List<ColumnInfo> columns;
  TableInfo(this.name, this.columns);

  factory TableInfo.fromJson(Map json) => TableInfo(
        json['name'] as String,
        [
          for (final c in (json['columns'] as List? ?? const []))
            ColumnInfo.fromJson(c as Map),
        ],
      );

  Iterable<String> get columnNames => columns.map((c) => c.name);
  Set<String> get primaryKeys =>
      {for (final c in columns) if (c.isPrimaryKey) c.name};
}
