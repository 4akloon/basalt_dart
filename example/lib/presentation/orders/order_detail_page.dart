import 'package:basalt_example/core/di/injector.dart';
import 'package:basalt_example/core/util/formatters.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/common/status_views.dart';
import 'package:basalt_example/presentation/orders/order_detail_cubit.dart';
import 'package:basalt_example/presentation/orders/order_detail_state.dart';
import 'package:basalt_example/presentation/orders/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full order view — customer, shipping, line items, total and status control.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderDetailCubit(getIt(), orderId)..load(),
      child: _OrderDetailView(orderId: orderId),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView({required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: BlocBuilder<OrderDetailCubit, OrderDetailState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.failure:
              return ErrorView(
                message: state.error ?? 'Something went wrong',
                onRetry: () => context.read<OrderDetailCubit>().load(),
              );
            case LoadStatus.success:
              return _Content(summary: state.summary!, updating: state.updating);
          }
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.summary, required this.updating});

  final OrderSummary summary;
  final bool updating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = summary.order;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.customer?.name ?? 'Customer #${order.customerId}',
                style: theme.textTheme.titleLarge,
              ),
            ),
            OrderStatusChip(status: order.status),
          ],
        ),
        Text('Placed ${formatDate(order.placedAt)}',
            style: theme.textTheme.bodySmall),
        if (order.shippingAddress != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(order.shippingAddress!.formatted)),
            ],
          ),
        ],
        const Divider(height: 32),
        Text('Items', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in summary.items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.product?.name ?? 'Product #${item.productId}'),
            subtitle: Text(
              '${item.quantity} × ${formatMoney(item.unitPrice)}'
              '${item.product?.category != null ? ' · ${item.product!.category!.name}' : ''}',
            ),
            trailing: Text(formatMoney(item.lineTotal)),
          ),
        const Divider(height: 32),
        Row(
          children: [
            Text('Total', style: theme.textTheme.titleLarge),
            const Spacer(),
            Text(formatMoney(summary.total), style: theme.textTheme.headlineSmall),
          ],
        ),
        const SizedBox(height: 24),
        Text('Update status', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final status in OrderStatus.values)
              ChoiceChip(
                label: Text(status.label),
                selected: order.status == status,
                onSelected: updating || order.status == status
                    ? null
                    : (_) =>
                        context.read<OrderDetailCubit>().changeStatus(status),
              ),
          ],
        ),
      ],
    );
  }
}
