/// The outcome of an edit-row dialog: which row to target ([key]) and the new
/// column values to write ([changes]).
class RowEdit {
  /// Creates an edit targeting [key] with [changes].
  RowEdit(this.key, this.changes);

  /// Key columns (typically the primary key) identifying the row.
  final Map<String, Object?> key;

  /// Column values to write.
  final Map<String, Object?> changes;
}
