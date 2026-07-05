import 'package:basalt_example/core/di/injector.dart';
import 'package:basalt_example/core/util/formatters.dart';
import 'package:basalt_example/domain/entities/views/customer_profile.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/common/refresh_icon_button.dart';
import 'package:basalt_example/presentation/common/status_views.dart';
import 'package:basalt_example/presentation/customers/customer_profile_cubit.dart';
import 'package:basalt_example/presentation/customers/customer_profile_state.dart';
import 'package:basalt_example/presentation/orders/order_detail_page.dart';
import 'package:basalt_example/presentation/orders/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A customer profile — loyalty, lifetime spend, addresses and order history.
class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerProfileCubit(getIt(), customerId)..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer'),
        actions: [
          RefreshIconButton(
            onRefresh: () => context.read<CustomerProfileCubit>().load(),
          ),
        ],
      ),
      body: BlocBuilder<CustomerProfileCubit, CustomerProfileState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.failure:
              return ErrorView(
                message: state.error ?? 'Something went wrong',
                onRetry: () => context.read<CustomerProfileCubit>().load(),
              );
            case LoadStatus.success:
              return _Content(profile: state.profile!);
          }
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = profile.customer;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(customer.name.characters.first,
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: theme.textTheme.titleLarge),
                  Text(customer.email, style: theme.textTheme.bodySmall),
                  Text('Joined ${formatDate(customer.joinedAt)}',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Chip(label: Text(customer.tier.label)),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Lifetime spend'),
            trailing: Text(
              formatMoney(profile.totalSpent),
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Addresses', style: theme.textTheme.titleMedium),
        if (profile.addresses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No addresses on file'),
          )
        else
          for (final address in profile.addresses)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(address.label),
              subtitle: Text(address.formatted),
            ),
        const Divider(height: 32),
        Text('Orders (${profile.orders.length})',
            style: theme.textTheme.titleMedium),
        if (profile.orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No orders yet'),
          )
        else
          for (final summary in profile.orders)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('#${summary.order.id}')),
              title: Text('${summary.itemCount} items · '
                  '${formatDate(summary.order.placedAt)}'),
              subtitle: OrderStatusChip(status: summary.order.status),
              trailing: Text(formatMoney(summary.total)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OrderDetailPage(orderId: summary.order.id),
                ),
              ),
            ),
      ],
    );
  }
}
