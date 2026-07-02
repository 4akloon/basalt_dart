/// One column predicate sent to `ext.diesel.getTableData`.
class ColumnFilter {
  final String column;
  final String op;
  final Object? value;
  ColumnFilter(this.column, this.op, [this.value]);

  Map<String, Object?> toJson() =>
      {'column': column, 'op': op, 'value': value};
}
