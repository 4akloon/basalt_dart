import 'package:flutter/material.dart';

import 'models/column_filter.dart';
import 'models/table_info.dart';
import 'value_coerce.dart';

/// Dialog that builds a single [ColumnFilter] for a table. Pops the built filter
/// on "Add", or null on cancel.
class AddFilterDialog extends StatefulWidget {
  final TableInfo table;
  const AddFilterDialog(this.table, {super.key});

  @override
  State<AddFilterDialog> createState() => _AddFilterDialogState();
}

class _AddFilterDialogState extends State<AddFilterDialog> {
  late String _column = widget.table.columns.first.name;
  String _op = 'eq';
  final _value = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  String get _columnType =>
      widget.table.columns.firstWhere((c) => c.name == _column).type;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add filter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _column,
            decoration: const InputDecoration(labelText: 'Column'),
            items: [
              for (final c in widget.table.columns)
                DropdownMenuItem(value: c.name, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _column = v ?? _column),
          ),
          DropdownButtonFormField<String>(
            initialValue: _op,
            decoration: const InputDecoration(labelText: 'Operator'),
            items: [
              for (final e in filterOps.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _op = v ?? _op),
          ),
          if (opNeedsValue(_op))
            TextField(
              controller: _value,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Value'),
              onSubmitted: (_) => _submit(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }

  void _submit() {
    final value = opNeedsValue(_op)
        ? (_op == 'like'
            ? _value.text
            : coerceValue(_columnType, _value.text))
        : null;
    Navigator.pop(context, ColumnFilter(_column, _op, value));
  }
}
