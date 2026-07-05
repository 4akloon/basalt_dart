import 'package:basalt_example/core/di/injector.dart';
import 'package:basalt_example/core/util/formatters.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/common/status_views.dart';
import 'package:basalt_example/presentation/orders/order_detail_page.dart';
import 'package:basalt_example/presentation/orders/order_status_chip.dart';
import 'package:basalt_example/presentation/orders/orders_cubit.dart';
import 'package:basalt_example/presentation/orders/orders_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Orders tab — the most recent orders with their totals.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrdersCubit(getIt())..load(),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.failure:
              return ErrorView(
                message: state.error ?? 'Something went wrong',
                onRetry: () => context.read<OrdersCubit>().load(),
              );
            case LoadStatus.success:
              break;
          }
          if (state.orders.isEmpty) {
            return const EmptyView(message: 'No orders yet');
          }
          return RefreshIndicator(
            onRefresh: () => context.read<OrdersCubit>().load(),
            child: ListView.builder(
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final summary = state.orders[index];
                final order = summary.order;
                return ListTile(
                  leading: CircleAvatar(child: Text('#${order.id}')),
                  title: Text(order.customer?.name ?? 'Customer #${order.customerId}'),
                  subtitle: Text(
                    '${summary.itemCount} items · ${formatDate(order.placedAt)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatMoney(summary.total)),
                      OrderStatusChip(status: order.status),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailPage(orderId: order.id),
                      ),
                    );
                    if (context.mounted) context.read<OrdersCubit>().load();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
