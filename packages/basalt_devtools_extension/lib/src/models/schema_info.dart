import 'table_info.dart';

/// The schema of one instance.
class SchemaInfo {
  final List<TableInfo> tables;
  SchemaInfo(this.tables);

  factory SchemaInfo.fromJson(Map json) => SchemaInfo([
        for (final t in (json['tables'] as List? ?? const []))
          TableInfo.fromJson(t as Map),
      ]);
}
