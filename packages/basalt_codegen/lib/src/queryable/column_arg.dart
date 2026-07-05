/// One constructor column mapped to a schema accessor expression, plus its
/// read/write direction from `@Column(readOnly:)` / `@Column(writeOnly:)`.
final class ColumnArg {
  const ColumnArg({
    required this.paramName,
    required this.isNamed,
    required this.columnExpr,
    this.readOnly = false,
    this.writeOnly = false,
  });
  final String paramName;
  final bool isNamed;
  final String columnExpr;

  /// Excluded from INSERT and `UPDATE … SET` (autoincrement PK, server default).
  final bool readOnly;

  /// Excluded from the generated SELECT row reader (the parameter must be
  /// optional so its default is used).
  final bool writeOnly;
}
