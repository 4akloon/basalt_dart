import 'package:basalt_example/core/di/injector.dart';
import 'package:basalt_example/core/util/formatters.dart';
import 'package:basalt_example/domain/entities/review.dart';
import 'package:basalt_example/domain/entities/views/product_with_stats.dart';
import 'package:basalt_example/presentation/cart/cart_cubit.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/common/star_rating.dart';
import 'package:basalt_example/presentation/common/status_views.dart';
import 'package:basalt_example/presentation/product_detail/product_detail_cubit.dart';
import 'package:basalt_example/presentation/product_detail/product_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Current shopper" used when writing a review, for demo purposes.
const _currentCustomerId = 1;

/// Product-detail tab: description, category, aggregate rating and reviews.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailCubit(getIt(), getIt(), productId)..load(),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.failure:
              return ErrorView(
                message: state.error ?? 'Something went wrong',
                onRetry: () => context.read<ProductDetailCubit>().load(),
              );
            case LoadStatus.success:
              return _Content(data: state.data!);
          }
        },
      ),
      floatingActionButton: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          if (state.status != LoadStatus.success) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: state.submitting
                ? null
                : () => _openReviewDialog(context),
            icon: const Icon(Icons.rate_review),
            label: const Text('Review'),
          );
        },
      ),
    );
  }

  Future<void> _openReviewDialog(BuildContext context) async {
    final cubit = context.read<ProductDetailCubit>();
    final result = await showDialog<(int, String?)>(
      context: context,
      builder: (_) => const _ReviewDialog(),
    );
    if (result == null) return;
    await cubit.addReview(
      customerId: _currentCustomerId,
      rating: result.$1,
      comment: result.$2,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final ProductWithStats data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = data.product;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(product.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        if (product.category != null)
          Chip(label: Text(product.category!.name)),
        const SizedBox(height: 12),
        Text(product.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(formatMoney(product.price), style: theme.textTheme.headlineSmall),
            const Spacer(),
            FilledButton.icon(
              onPressed: product.inStock
                  ? () {
                      context.read<CartCubit>().add(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to cart'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(product.inStock ? 'Add to cart' : 'Out of stock'),
            ),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Text('Reviews', style: theme.textTheme.titleLarge),
            const SizedBox(width: 12),
            if (data.averageRating != null) ...[
              StarRating(rating: data.averageRating!),
              const SizedBox(width: 6),
              Text(
                '${data.averageRating!.toStringAsFixed(1)} (${data.reviewCount})',
                style: theme.textTheme.bodyMedium,
              ),
            ] else
              Text('No reviews yet', style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),
        for (final review in data.reviews) _ReviewTile(review: review),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(review.customer?.name.characters.first ?? '?'),
      ),
      title: Row(
        children: [
          Text(review.customer?.name ?? 'Anonymous'),
          const SizedBox(width: 8),
          StarRating(rating: review.rating.toDouble(), size: 14),
        ],
      ),
      subtitle: review.comment == null ? null : Text(review.comment!),
      trailing: Text(formatDate(review.createdAt),
          style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write a review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  icon: Icon(i <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber),
                  onPressed: () => setState(() => _rating = i),
                ),
            ],
          ),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Comment (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            Navigator.of(context).pop((_rating, text.isEmpty ? null : text));
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
