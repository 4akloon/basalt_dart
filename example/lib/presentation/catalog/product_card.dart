import 'package:basalt_example/core/util/formatters.dart';
import 'package:basalt_example/domain/entities/product.dart';
import 'package:flutter/material.dart';

/// A single product row in the catalogue list.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(product.name.characters.first),
        ),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.category != null)
              Text(
                product.category!.name,
                style: theme.textTheme.bodySmall,
              ),
            Text(
              product.inStock ? '${product.stock} in stock' : 'Out of stock',
              style: theme.textTheme.bodySmall?.copyWith(
                color: product.inStock ? Colors.green : Colors.redAccent,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(product.price),
              style: theme.textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: 'Add to cart',
              onPressed: product.inStock ? onAddToCart : null,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
