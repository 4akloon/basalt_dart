import 'package:flutter/material.dart';

/// AppBar refresh action — calls [onRefresh] (typically a cubit `.load()`).
class RefreshIconButton extends StatelessWidget {
  const RefreshIconButton({required this.onRefresh, super.key});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: 'Refresh',
      onPressed: () => onRefresh(),
    );
  }
}
