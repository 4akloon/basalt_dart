import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:flutter/material.dart';

/// A coloured chip reflecting an [OrderStatus].
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  Color get _color => switch (status) {
        OrderStatus.pending => Colors.orange,
        OrderStatus.paid => Colors.blue,
        OrderStatus.shipped => Colors.purple,
        OrderStatus.delivered => Colors.green,
        OrderStatus.cancelled => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      backgroundColor: _color,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
