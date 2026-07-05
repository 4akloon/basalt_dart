import 'package:basalt_example/core/di/injector.dart';
import 'package:basalt_example/core/util/formatters.dart';
import 'package:basalt_example/domain/entities/views/analytics.dart';
import 'package:basalt_example/presentation/analytics/analytics_cubit.dart';
import 'package:basalt_example/presentation/analytics/analytics_state.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/common/status_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Analytics tab — revenue by category, top customers and low-stock alerts.
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnalyticsCubit(getIt())..load(),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.failure:
              return ErrorView(
                message: state.error ?? 'Something went wrong',
                onRetry: () => context.read<AnalyticsCubit>().load(),
              );
            case LoadStatus.success:
              break;
          }
          return RefreshIndicator(
            onRefresh: () => context.read<AnalyticsCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RevenueSection(rows: state.revenueByCategory),
                const SizedBox(height: 24),
                _TopCustomersSection(rows: state.topCustomers),
                const SizedBox(height: 24),
                _LowStockSection(rows: state.lowStock),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _RevenueSection extends StatelessWidget {
  const _RevenueSection({required this.rows});
  final List<CategoryRevenue> rows;

  @override
  Widget build(BuildContext context) {
    final max = rows.isEmpty
        ? 1.0
        : rows.map((r) => r.revenue).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Revenue by category'),
        if (rows.isEmpty) const Text('No sales yet'),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(row.categoryName)),
                    Text('${formatMoney(row.revenue)} · ${row.unitsSold} units'),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: max == 0 ? 0 : row.revenue / max,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopCustomersSection extends StatelessWidget {
  const _TopCustomersSection({required this.rows});
  final List<TopCustomer> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Top customers'),
        if (rows.isEmpty) const Text('No customers yet'),
        for (final (index, row) in rows.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(row.customer.name),
            subtitle: Text('${row.orderCount} orders · ${row.customer.tier.label}'),
            trailing: Text(formatMoney(row.totalSpent)),
          ),
      ],
    );
  }
}

class _LowStockSection extends StatelessWidget {
  const _LowStockSection({required this.rows});
  final List<LowStockProduct> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Low stock'),
        if (rows.isEmpty) const Text('All products well stocked'),
        for (final row in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.warning_amber,
              color: row.stock == 0 ? Colors.red : Colors.orange,
            ),
            title: Text(row.product.name),
            subtitle: Text(row.product.category?.name ?? ''),
            trailing: Text('${row.stock} left'),
          ),
      ],
    );
  }
}
