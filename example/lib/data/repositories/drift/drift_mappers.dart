import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/domain/entities/address.dart';
import 'package:basalt_example/domain/entities/category.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/loyalty_tier.dart';
import 'package:basalt_example/domain/entities/order.dart';
import 'package:basalt_example/domain/entities/order_item.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/entities/product.dart';
import 'package:basalt_example/domain/entities/review.dart';

/// Row → domain converters for the drift backend — the drift counterparts of
/// the basalt `*RowMapper` extensions under `data/mappers/`. Each takes a drift
/// data class (`DriftCustomer`, `DriftProduct`, …) plus any already-resolved
/// relations and returns the matching domain entity, decoding the same raw
/// storage shapes (enum text, epoch millis, 0/1 booleans).

/// Converts a [DriftCustomer] into a domain [Customer].
Customer customerToDomain(DriftCustomer c) => Customer(
      id: c.id,
      name: c.name,
      email: c.email,
      tier: LoyaltyTier.values.byName(c.loyaltyTier),
      joinedAt: DateTime.fromMillisecondsSinceEpoch(c.createdAt),
    );

/// Converts a [DriftCategory] into a domain [Category] with an optional
/// resolved [parent].
Category categoryToDomain(DriftCategory c, {Category? parent}) => Category(
      id: c.id,
      name: c.name,
      parentId: c.parentId,
      parent: parent,
    );

/// Converts a [DriftProduct] into a domain [Product] (0/1 → bool) with an
/// optional resolved [category].
Product productToDomain(DriftProduct p, {Category? category}) => Product(
      id: p.id,
      name: p.name,
      description: p.description,
      price: p.price,
      stock: p.stock,
      categoryId: p.categoryId,
      isActive: p.isActive == 1,
      metadata: p.metadata,
      category: category,
    );

/// Converts a [DriftAddress] into a domain [Address].
Address addressToDomain(DriftAddress a) => Address(
      id: a.id,
      customerId: a.customerId,
      label: a.label,
      city: a.city,
      street: a.street,
    );

/// Converts a [DriftOrder] into a domain [Order] with optional resolved
/// [customer] / [shippingAddress] relations.
Order orderToDomain(
  DriftOrder o, {
  Customer? customer,
  Address? shippingAddress,
}) =>
    Order(
      id: o.id,
      customerId: o.customerId,
      status: OrderStatus.values.byName(o.status),
      placedAt: DateTime.fromMillisecondsSinceEpoch(o.createdAt),
      shippingAddressId: o.shippingAddressId,
      customer: customer,
      shippingAddress: shippingAddress,
    );

/// Converts a [DriftOrderItem] into a domain [OrderItem] with an optional
/// resolved [product].
OrderItem orderItemToDomain(DriftOrderItem i, {Product? product}) => OrderItem(
      id: i.id,
      orderId: i.orderId,
      productId: i.productId,
      quantity: i.quantity,
      unitPrice: i.unitPrice,
      product: product,
    );

/// Converts a [DriftReview] into a domain [Review] with an optional resolved
/// [author] (its customer).
Review reviewToDomain(DriftReview r, {Customer? author}) => Review(
      id: r.id,
      productId: r.productId,
      customerId: r.customerId,
      rating: r.rating,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
      comment: r.comment,
      customer: author,
    );
