import 'package:basalt/devtools_client.dart';
import 'package:flutter/material.dart';

import 'row_edit.dart';
import 'schema_x.dart';
import 'value_coerce.dart';

/// Dialog to edit one row. Primary-key fields are read-only and form the WHERE
/// key; the rest are editable. Pops a [RowEdit] with only the changed columns,
/// or null on cancel / when nothing changed.
class EditRowDialog extends StatefulWidget {
  final TableDto table;
  final List<String> columns;
  final List<Object?> row;

  const EditRowDialog({
    super.key,
    required this.table,
    required this.columns,
    required this.row,
  });

  @override
  State<EditRowDialog> createState() => _EditRowDialogState();
}

class _EditRowDialogState extends State<EditRowDialog> {
  late final Map<String, String> _original;
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _original = {
      for (var i = 0; i < widget.columns.length; i++)
        widget.columns[i]: _text(i < widget.row.length ? widget.row[i] : null),
    };
    _controllers = {
      for (final entry in _original.entries)
        entry.key: TextEditingController(text: entry.value),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _text(Object? value) => value?.toString() ?? '';

  Set<String> get _pks => widget.table.primaryKeys;

  ColumnDto _info(String name) =>
      widget.table.columns.firstWhere((c) => c.name == name);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.table.name} row'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final name in widget.columns)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(
                    controller: _controllers[name],
                    readOnly: _pks.contains(name),
                    decoration: InputDecoration(
                      labelText: _pks.contains(name) ? '$name (key)' : name,
                      helperText: _info(name).type,
                      isDense: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    final changes = <String, Object?>{};
    for (final name in widget.columns) {
      if (_pks.contains(name)) continue;
      final text = _controllers[name]?.text ?? '';
      if (text == _original[name]) continue;
      final col = _info(name);
      changes[name] = coerceValue(col.type, text, emptyIsNull: col.isNullable);
    }
    if (changes.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final key = {
      for (final name in _pks)
        name: coerceValue(_info(name).type, _original[name] ?? ''),
    };
    Navigator.pop(context, RowEdit(key, changes));
  }
}
