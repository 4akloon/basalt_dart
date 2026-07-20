import 'package:basalt/devtools_client.dart';
import 'package:flutter/material.dart';

import 'add_filter_dialog.dart';
import 'value_coerce.dart';

/// Shows active filters as removable chips plus an "Add filter" action.
class FilterBar extends StatelessWidget {
  final TableDto table;
  final List<ColumnFilter> filters;
  final ValueChanged<List<ColumnFilter>> onChanged;

  const FilterBar({
    super.key,
    required this.table,
    required this.filters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final f in filters)
            Chip(
              label: Text(_label(f)),
              onDeleted: () => onChanged([...filters]..remove(f)),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Add filter'),
            onPressed: () => _add(context),
          ),
          if (filters.isNotEmpty)
            TextButton(
              onPressed: () => onChanged(const []),
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final filter = await showDialog<ColumnFilter>(
      context: context,
      builder: (_) => AddFilterDialog(table),
    );
    if (filter != null) onChanged([...filters, filter]);
  }

  String _label(ColumnFilter f) {
    final op = filterOps[f.op] ?? f.op;
    return opNeedsValue(f.op)
        ? '${f.column} $op ${f.value}'
        : '${f.column} $op';
  }
}
