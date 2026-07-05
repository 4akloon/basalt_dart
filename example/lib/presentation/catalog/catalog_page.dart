import 'package:basalt_example/core/di/injector.dart';
import 'package:basalt_example/presentation/cart/cart_cubit.dart';
import 'package:basalt_example/presentation/catalog/catalog_cubit.dart';
import 'package:basalt_example/presentation/catalog/catalog_state.dart';
import 'package:basalt_example/presentation/catalog/product_card.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/common/refresh_icon_button.dart';
import 'package:basalt_example/presentation/common/status_views.dart';
import 'package:basalt_example/presentation/product_detail/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Catalogue tab — searchable, category-filterable product list.
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CatalogCubit(getIt(), getIt())..load(),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatelessWidget {
  const _CatalogView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          RefreshIconButton(
            onRefresh: () => context.read<CatalogCubit>().load(),
          ),
        ],
      ),
      body: Column(
        children: [
          const _SearchField(),
          const _CategoryFilter(),
          Expanded(
            child: BlocBuilder<CatalogCubit, CatalogState>(
              builder: (context, state) {
                switch (state.status) {
                  case LoadStatus.initial:
                  case LoadStatus.loading:
                    if (state.products.isEmpty) return const LoadingView();
                  case LoadStatus.failure:
                    return ErrorView(
                      message: state.error ?? 'Something went wrong',
                      onRetry: () => context.read<CatalogCubit>().load(),
                    );
                  case LoadStatus.success:
                    break;
                }
                if (state.products.isEmpty) {
                  return const EmptyView(message: 'No products match your filters');
                }
                return ListView.builder(
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductDetailPage(productId: product.id),
                        ),
                      ),
                      onAddToCart: () {
                        context.read<CartCubit>().add(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search products',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) => context.read<CatalogCubit>().search(value),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      buildWhen: (a, b) =>
          a.categories != b.categories ||
          a.selectedCategoryId != b.selectedCategoryId,
      builder: (context, state) {
        if (state.categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: state.selectedCategoryId == null,
                  onSelected: (_) =>
                      context.read<CatalogCubit>().selectCategory(null),
                ),
              ),
              for (final category in state.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: state.selectedCategoryId == category.id,
                    onSelected: (_) =>
                        context.read<CatalogCubit>().selectCategory(category.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
