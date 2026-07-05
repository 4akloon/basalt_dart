import 'package:basalt_example/presentation/analytics/analytics_page.dart';
import 'package:basalt_example/presentation/cart/cart_cubit.dart';
import 'package:basalt_example/presentation/cart/cart_state.dart';
import 'package:basalt_example/presentation/cart/cart_page.dart';
import 'package:basalt_example/presentation/catalog/catalog_page.dart';
import 'package:basalt_example/presentation/customers/customers_page.dart';
import 'package:basalt_example/presentation/orders/orders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The app's bottom-navigation shell hosting the five top-level tabs. Each tab
/// keeps its own state via an [IndexedStack].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    CatalogPage(),
    CartPage(),
    OrdersPage(),
    CustomersPage(),
    AnalyticsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Catalogue',
          ),
          NavigationDestination(
            icon: BlocBuilder<CartCubit, CartState>(
              builder: (context, state) => Badge(
                isLabelVisible: state.count > 0,
                label: Text('${state.count}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
