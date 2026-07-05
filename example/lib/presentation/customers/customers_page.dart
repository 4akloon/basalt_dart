import 'package:basalt_example/core/di/injector.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/common/status_views.dart';
import 'package:basalt_example/presentation/customers/customer_profile_page.dart';
import 'package:basalt_example/presentation/customers/customers_cubit.dart';
import 'package:basalt_example/presentation/customers/customers_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Customers tab — a directory of shoppers.
class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomersCubit(getIt())..load(),
      child: const _CustomersView(),
    );
  }
}

class _CustomersView extends StatelessWidget {
  const _CustomersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: BlocBuilder<CustomersCubit, CustomersState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.failure:
              return ErrorView(
                message: state.error ?? 'Something went wrong',
                onRetry: () => context.read<CustomersCubit>().load(),
              );
            case LoadStatus.success:
              break;
          }
          if (state.customers.isEmpty) {
            return const EmptyView(message: 'No customers');
          }
          return ListView.builder(
            itemCount: state.customers.length,
            itemBuilder: (context, index) {
              final customer = state.customers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(customer.name.characters.first)),
                title: Text(customer.name),
                subtitle: Text(customer.email),
                trailing: Chip(label: Text(customer.tier.label)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CustomerProfilePage(customerId: customer.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
