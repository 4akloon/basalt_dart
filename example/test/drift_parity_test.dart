import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/drift/drift_seed.dart';
import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/data/repositories/analytics_repository_impl.dart';
import 'package:basalt_example/data/repositories/category_repository_impl.dart';
import 'package:basalt_example/data/repositories/customer_repository_impl.dart';
import 'package:basalt_example/data/repositories/drift/drift_analytics_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_category_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_customer_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_order_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_product_repository.dart';
import 'package:basalt_example/data/repositories/drift/drift_review_repository.dart';
import 'package:basalt_example/data/repositories/order_repository_impl.dart';
import 'package:basalt_example/data/repositories/product_repository_impl.dart';
import 'package:basalt_example/domain/entities/new_order.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/entities/views/order_list_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_database.dart';

/// The drift backend must be a drop-in equal of the basalt backend: same demo
/// seed, same domain results out of every repository. These tests run *both*
/// backends in memory and assert they agree, method for method.
void main() {
  late Connection basalt;
  late ShopDriftDatabase drift;

  setUp(() async {
    basalt = await openTestDatabase();
    drift = ShopDriftDatabase(NativeDatabase.memory());
    await DriftSeed.run(drift);
  });

  tearDown(() async {
    await drift.close();
    await basalt.close();
  });

  test('categories — all() and tree() agree', () async {
    final b = await CategoryRepositoryImpl(basalt).all();
    final d = await DriftCategoryRepository(drift).all();
    expect(d.map((c) => c.name), b.map((c) => c.name));
    expect(d.map((c) => c.parentId), b.map((c) => c.parentId));

    final bt = await CategoryRepositoryImpl(basalt).tree();
    final dt = await DriftCategoryRepository(drift).tree();
    expect(dt.map((n) => n.category.name), bt.map((n) => n.category.name));
    expect(dt.map((n) => n.productCount), bt.map((n) => n.productCount));
    expect(
      dt.map((n) => n.children.length),
      bt.map((n) => n.children.length),
    );
  });

  test('products — list() (plain, search, category filter) agrees', () async {
    final b = ProductRepositoryImpl(basalt);
    final d = DriftProductRepository(drift);

    for (final args in const [
      (search: null, categoryId: null),
      (search: 'Laptop', categoryId: null),
      (search: null, categoryId: 2),
      (search: 'phone', categoryId: 3),
    ]) {
      final bl =
          await b.list(search: args.search, categoryId: args.categoryId);
      final dl =
          await d.list(search: args.search, categoryId: args.categoryId);
      expect(dl.map((p) => p.name), bl.map((p) => p.name), reason: '$args');
      expect(dl.map((p) => p.category?.name), bl.map((p) => p.category?.name));
    }
  });

  test('products — detail() rating, reviews and metadata agree', () async {
    final b = await ProductRepositoryImpl(basalt).detail(1);
    final d = await DriftProductRepository(drift).detail(1);
    expect(d!.product.name, b!.product.name);
    expect(d.product.metadata, b.product.metadata);
    expect(d.reviewCount, b.reviewCount);
    expect(d.averageRating, b.averageRating);
    // Same authors, order-independent: basalt's fold emits reviews in id order
    // while drift honours the `created_at DESC` intent — a display-order detail,
    // not a data difference.
    expect(
      d.reviews.map((r) => r.customer?.name).toSet(),
      b.reviews.map((r) => r.customer?.name).toSet(),
    );
    expect(await DriftProductRepository(drift).detail(9999), isNull);
  });

  test('customers — all() and profile() agree', () async {
    final b = await CustomerRepositoryImpl(basalt).all();
    final d = await DriftCustomerRepository(drift).all();
    expect(d.map((c) => c.name), b.map((c) => c.name));
    expect(d.map((c) => c.tier), b.map((c) => c.tier));

    final bp = await CustomerRepositoryImpl(basalt).profile(1);
    final dp = await DriftCustomerRepository(drift).profile(1);
    expect(dp!.addresses.length, bp!.addresses.length);
    expect(dp.orders.length, bp.orders.length);
    expect(dp.totalSpent, bp.totalSpent);
  });

  test('orders — recent() and detail() agree', () async {
    final b = await OrderRepositoryImpl(basalt).recent();
    final d = await DriftOrderRepository(drift).recent();
    // Same orders present (order-independent): basalt's parent-limit subquery
    // drops the `created_at DESC` ordering and yields id order, while drift
    // returns newest-first. Compare the set of (id → itemCount/total) instead.
    int byId(OrderListItem a, OrderListItem z) =>
        a.order.id.compareTo(z.order.id);
    final bs = [...b]..sort(byId);
    final ds = [...d]..sort(byId);
    expect(ds.map((o) => o.order.id), bs.map((o) => o.order.id));
    expect(ds.map((o) => o.order.status), bs.map((o) => o.order.status));
    expect(ds.map((o) => o.itemCount), bs.map((o) => o.itemCount));
    expect(ds.map((o) => o.total), bs.map((o) => o.total));

    final bd = await OrderRepositoryImpl(basalt).detail(3);
    final dd = await DriftOrderRepository(drift).detail(3);
    expect(dd!.items.length, bd!.items.length);
    expect(dd.total, bd.total);
    expect(
      dd.items.map((i) => i.product?.name),
      bd.items.map((i) => i.product?.name),
    );
  });

  test('analytics — revenue, top customers and low stock agree', () async {
    final ba = AnalyticsRepositoryImpl(basalt);
    final da = DriftAnalyticsRepository(drift);

    final br = await ba.revenueByCategory();
    final dr = await da.revenueByCategory();
    expect(dr.map((r) => r.categoryName), br.map((r) => r.categoryName));
    expect(dr.map((r) => r.revenue), br.map((r) => r.revenue));
    expect(dr.map((r) => r.unitsSold), br.map((r) => r.unitsSold));

    final bt = await ba.topCustomers();
    final dt = await da.topCustomers();
    expect(dt.map((c) => c.customer.name), bt.map((c) => c.customer.name));
    expect(dt.map((c) => c.totalSpent), bt.map((c) => c.totalSpent));
    expect(dt.map((c) => c.orderCount), bt.map((c) => c.orderCount));

    final bl = await ba.lowStock();
    final dl = await da.lowStock();
    expect(dl.map((p) => p.product.name), bl.map((p) => p.product.name));
    expect(dl.map((p) => p.stock), bl.map((p) => p.stock));
  });

  test('writes — placeOrder decrements stock, updateStatus and addReview',
      () async {
    final orders = DriftOrderRepository(drift);
    final products = DriftProductRepository(drift);

    final before = (await products.detail(3))!.product.stock;
    final orderId = await orders.placeOrder(const NewOrder(
      customerId: 1,
      shippingAddressId: 1,
      lines: [NewOrderLine(productId: 3, quantity: 2, unitPrice: 999.0)],
    ));
    expect(orderId, greaterThan(0));
    expect((await products.detail(3))!.product.stock, before - 2);

    final placed = await orders.detail(orderId);
    expect(placed!.items.single.quantity, 2);
    expect(placed.order.status, OrderStatus.pending);

    await orders.updateStatus(orderId, OrderStatus.paid);
    expect((await orders.detail(orderId))!.order.status, OrderStatus.paid);

    await DriftReviewRepository(drift)
        .add(productId: 3, customerId: 1, rating: 5, comment: 'Great');
    expect((await products.detail(3))!.reviewCount, greaterThan(0));
  });
}
