/// A table column reported by the app's schema introspection.
class ColumnInfo {
  final String name;
  final String type;
  final bool isNullable;
  final bool isPrimaryKey;
  final String? fkTable;
  ColumnInfo(
      this.name, this.type, this.isNullable, this.isPrimaryKey, this.fkTable);

  factory ColumnInfo.fromJson(Map json) => ColumnInfo(
        json['name'] as String,
        json['type'] as String,
        json['isNullable'] as bool? ?? true,
        json['isPrimaryKey'] as bool? ?? false,
        (json['foreignKey'] as Map?)?['table'] as String?,
      );
}
