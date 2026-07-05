import 'package:basalt_example/core/di/injector.dart';
import 'package:basalt_example/core/util/formatters.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/repositories/customer_repository.dart';
import 'package:basalt_example/presentation/cart/cart_cubit.dart';
import 'package:basalt_example/presentation/cart/cart_state.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/common/refresh_icon_button.dart';
import 'package:basalt_example/presentation/common/status_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cart tab — line items, quantity steppers, and checkout.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<Customer>> _customers =
      getIt<CustomerRepository>().all();
  Customer? _selected;

  void _refresh() {
    setState(() {
      _customers = getIt<CustomerRepository>().all();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          RefreshIconButton(onRefresh: () async => _refresh()),
        ],
      ),
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state.checkout == LoadStatus.success && state.lastOrderId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order #${state.lastOrderId} placed!')),
            );
          } else if (state.checkout == LoadStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Checkout failed: ${state.error}')),
            );
          }
        },
        builder: (context, state) {
          if (state.isEmpty) {
            return const EmptyView(
              message: 'Your cart is empty',
              icon: Icons.shopping_cart_outlined,
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text(formatMoney(item.product.price)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => context
                                .read<CartCubit>()
                                .setQuantity(item.product.id, item.quantity - 1),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => context
                                .read<CartCubit>()
                                .setQuantity(item.product.id, item.quantity + 1),
                          ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              formatMoney(item.lineTotal),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _CheckoutBar(
                total: state.total,
                busy: state.checkout == LoadStatus.loading,
                customers: _customers,
                selected: _selected,
                onSelect: (c) => setState(() => _selected = c),
                onCheckout: () {
                  final customer = _selected;
                  if (customer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a customer first')),
                    );
                    return;
                  }
                  context.read<CartCubit>().checkout(customerId: customer.id);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.busy,
    required this.customers,
    required this.selected,
    required this.onSelect,
    required this.onCheckout,
  });

  final double total;
  final bool busy;
  final Future<List<Customer>> customers;
  final Customer? selected;
  final ValueChanged<Customer?> onSelect;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<List<Customer>>(
              future: customers,
              builder: (context, snapshot) {
                final list = snapshot.data ?? const [];
                return DropdownButtonFormField<Customer>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'Checkout as',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final customer in list)
                      DropdownMenuItem(
                        value: customer,
                        child: Text(customer.name),
                      ),
                  ],
                  onChanged: onSelect,
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(formatMoney(total),
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onCheckout,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: Text(busy ? 'Placing order…' : 'Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
