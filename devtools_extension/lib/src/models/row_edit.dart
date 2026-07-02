/// The outcome of an edit-row dialog: which row to target ([key]) and the new
/// column values to write ([changes]).
class RowEdit {
  final Map<String, Object?> key;
  final Map<String, Object?> changes;
  RowEdit(this.key, this.changes);
}
