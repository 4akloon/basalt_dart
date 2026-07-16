// Micro-benchmark comparing every repository method on the two backends
// (basalt + drift) against identical in-memory databases.
//
// Run from the example package root:
//   dart run benchmark/repository_benchmark.dart
//
// Both databases are seeded with the demo data and then amplified with the same
// volume of extra rows so the timings reflect real query work, not noise. Each
// method is warmed up, then run [readIters]/[writeIters] times; we report the
// median per call and the drift/basalt ratio.
//
// NOTE: this measures ORM + driver overhead for equivalent logical work on one
// machine; it is a relative comparison, not an absolute throughput number.
import 'package:basalt/basalt.dart';
import 'package:basalt/migration.dart';
import 'package:basalt_cli/basalt_cli.dart' show DirectoryMigrationSource;
import 'package:basalt_example/core/database/drift/drift_seed.dart';
import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/core/database/schema.dart' as s;
import 'package:basalt_example/core/database/seed_data.dart';
import 'package:basalt_example/data/models/order_item_write.dart';
import 'package:basalt_example/data/models/order_write.dart';
import 'package:basalt_example/data/models/product_write.dart';
import 'package:basalt_example/data/models/review_write.dart';
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
import 'package:basalt_example/data/repositories/review_repository_impl.dart';
import 'package:basalt_example/domain/entities/new_order.dart';
import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/repositories/analytics_repository.dart';
import 'package:basalt_example/domain/repositories/category_repository.dart';
import 'package:basalt_example/domain/repositories/customer_repository.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';
import 'package:basalt_example/domain/repositories/product_repository.dart';
import 'package:basalt_example/domain/repositories/review_repository.dart';
import 'package:basalt_sqlite/basalt_sqlite.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// ---- Tuning ---------------------------------------------------------------
const warmup = 20;
const readIters = 300;
const writeIters = 150;

// Extra rows added on top of the demo seed (same counts in both backends).
const extraProducts = 190; // -> ~200 products total
const extraOrders = 195; // -> ~200 orders, 3 items each
const itemsPerOrder = 3;
const extraReviewsOnP1 = 194; // -> ~200 reviews on product 1

void main() async {
  final basalt = await _buildBasalt();
  final drift = _buildDrift();
  await DriftSeed.run(drift);
  await _amplifyBasalt(basalt);
  await _amplifyDrift(drift);

  // Repositories (interface-typed, exactly what the app resolves).
  final CategoryRepository bCat = CategoryRepositoryImpl(basalt);
  final CategoryRepository dCat = DriftCategoryRepository(drift);
  final ProductRepository bProd = ProductRepositoryImpl(basalt);
  final ProductRepository dProd = DriftProductRepository(drift);
  final CustomerRepository bCust = CustomerRepositoryImpl(basalt);
  final CustomerRepository dCust = DriftCustomerRepository(drift);
  final OrderRepository bOrd = OrderRepositoryImpl(basalt);
  final OrderRepository dOrd = DriftOrderRepository(drift);
  final AnalyticsRepository bAn = AnalyticsRepositoryImpl(basalt);
  final AnalyticsRepository dAn = DriftAnalyticsRepository(drift);
  final ReviewRepository bRev = ReviewRepositoryImpl(basalt);
  final ReviewRepository dRev = DriftReviewRepository(drift);

  _printHeader();
  await _bench('category.all', () => bCat.all(), () => dCat.all());
  await _bench('category.tree', () => bCat.tree(), () => dCat.tree());
  await _bench('product.list (all)', () => bProd.list(), () => dProd.list());
  await _bench('product.list (search)',
      () => bProd.list(search: 'o'), () => dProd.list(search: 'o'));
  await _bench('product.detail', () => bProd.detail(1), () => dProd.detail(1));
  await _bench('customer.all', () => bCust.all(), () => dCust.all());
  await _bench(
      'customer.profile', () => bCust.profile(1), () => dCust.profile(1));
  await _bench('order.recent', () => bOrd.recent(), () => dOrd.recent());
  await _bench('order.detail', () => bOrd.detail(3), () => dOrd.detail(3));
  await _bench('analytics.revenue', () => bAn.revenueByCategory(),
      () => dAn.revenueByCategory());
  await _bench(
      'analytics.topCustomers', () => bAn.topCustomers(), () => dAn.topCustomers());
  await _bench('analytics.lowStock', () => bAn.lowStock(), () => dAn.lowStock());

  _printSep('writes');
  await _bench(
    'order.placeOrder',
    () => bOrd.placeOrder(_newOrder),
    () => dOrd.placeOrder(_newOrder),
    iters: writeIters,
  );
  await _bench(
    'review.add',
    () => bRev.add(productId: 1, customerId: 1, rating: 5),
    () => dRev.add(productId: 1, customerId: 1, rating: 5),
    iters: writeIters,
  );
  await _bench(
    'order.updateStatus',
    () => bOrd.updateStatus(1, OrderStatus.paid),
    () => dOrd.updateStatus(1, OrderStatus.paid),
    iters: writeIters,
  );

  _printNotes();
  await basalt.close();
  await drift.close();
}

const _newOrder = NewOrder(
  customerId: 1,
  shippingAddressId: 1,
  lines: [
    NewOrderLine(productId: 1, quantity: 1, unitPrice: 10),
    NewOrderLine(productId: 2, quantity: 2, unitPrice: 20),
  ],
);

// ---- Builders -------------------------------------------------------------

Future<Connection> _buildBasalt() async {
  final db = SqliteConnection.memory();
  await MigrationRunner(db, DirectoryMigrationSource('migrations')).runPending();
  await SeedData.run(db);
  return db;
}

ShopDriftDatabase _buildDrift() =>
    ShopDriftDatabase(NativeDatabase.memory());

Future<void> _amplifyBasalt(Connection db) async {
  await db.transaction((tx) async {
    // Batch inserts (one multi-row statement each) — mirrors Drift's
    // `insertAll` below for a fair comparison.
    await tx.execute([
      for (var i = 0; i < extraProducts; i++)
        ProductWrite(
          name: 'Bench Product $i',
          description: 'benchmark filler',
          price: 10.0 + i,
          stock: 100,
          categoryId: (i % 5) + 1,
          isActive: 1,
        ),
    ].toInsert());
    await tx.execute([
      for (var i = 0; i < extraReviewsOnP1; i++)
        ReviewWrite(
          productId: 1,
          customerId: (i % 4) + 1,
          rating: (i % 5) + 1,
          createdAt: i,
        ),
    ].toInsert());
    for (var i = 0; i < extraOrders; i++) {
      final orderId = (await tx.executeReturning(OrderWrite(
        customerId: (i % 4) + 1,
        status: OrderStatus.paid.name,
        createdAt: i,
      ).toInsert().returning([s.Orders.id]).map((r) => r.get(s.Orders.id))))
          .single;
      for (var j = 0; j < itemsPerOrder; j++) {
        await tx.execute(OrderItemWrite(
          orderId: orderId,
          productId: ((i + j) % 10) + 1,
          quantity: j + 1,
          unitPrice: 10.0 + j,
        ).toInsert());
      }
    }
  });
}

Future<void> _amplifyDrift(ShopDriftDatabase db) async {
  await db.batch((b) {
    b.insertAll(db.products, [
      for (var i = 0; i < extraProducts; i++)
        ProductsCompanion.insert(
          name: 'Bench Product $i',
          description: 'benchmark filler',
          price: 10.0 + i,
          stock: const Value(100),
          categoryId: (i % 5) + 1,
        ),
    ]);
    b.insertAll(db.reviews, [
      for (var i = 0; i < extraReviewsOnP1; i++)
        ReviewsCompanion.insert(
          productId: 1,
          customerId: (i % 4) + 1,
          rating: (i % 5) + 1,
          createdAt: i,
        ),
    ]);
  });
  for (var i = 0; i < extraOrders; i++) {
    await db.transaction(() async {
      final orderId = await db.into(db.orders).insert(OrdersCompanion.insert(
            customerId: (i % 4) + 1,
            status: Value(OrderStatus.paid.name),
            createdAt: i,
          ));
      for (var j = 0; j < itemsPerOrder; j++) {
        await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
              orderId: orderId,
              productId: ((i + j) % 10) + 1,
              quantity: j + 1,
              unitPrice: 10.0 + j,
            ));
      }
    });
  }
}

// ---- Runner ---------------------------------------------------------------

Future<void> _bench(
  String label,
  Future<Object?> Function() basalt,
  Future<Object?> Function() drift, {
  int iters = readIters,
}) async {
  final b = await _measure(basalt, iters);
  final d = await _measure(drift, iters);
  final ratio = d / b; // <1 => drift faster
  final winner = ratio < 0.95 ? 'drift' : (ratio > 1.05 ? 'basalt' : 'tie');
  // ignore: avoid_print
  print('${_pad(label, 24)} ${_us(b)} ${_us(d)} '
      '${_pad('${ratio.toStringAsFixed(2)}x', 8)} $winner');
}

Future<double> _measure(Future<Object?> Function() op, int iters) async {
  for (var i = 0; i < warmup; i++) {
    await op();
  }
  final samples = <int>[];
  final sw = Stopwatch();
  for (var i = 0; i < iters; i++) {
    sw
      ..reset()
      ..start();
    await op();
    sw.stop();
    samples.add(sw.elapsedMicroseconds);
  }
  samples.sort();
  return samples[samples.length ~/ 2].toDouble();
}

// ---- Output ---------------------------------------------------------------

void _printHeader() {
  // ignore: avoid_print
  print('\nRepository benchmark — basalt vs drift '
      '(~${10 + extraProducts} products, ~${5 + extraOrders} orders, '
      '~${6 + extraReviewsOnP1} reviews/p1)');
  // ignore: avoid_print
  print('median per call, $readIters iters (writes $writeIters)\n');
  // ignore: avoid_print
  print('${_pad('method', 24)} ${_pad('basalt', 11)} ${_pad('drift', 11)} '
      '${_pad('drift/basalt', 8)} winner');
  _printSep('reads');
}

void _printSep(String title) {
  // ignore: avoid_print
  print('-- $title ${'-' * (58 - title.length)}');
}

void _printNotes() {
  // ignore: avoid_print
  print('\nNotes: in-memory SQLite, single machine, relative comparison only.\n'
      'Both backends return identical results (see test/drift_parity_test.dart).');
}

String _pad(String s, int w) => s.padRight(w);
String _us(double micros) => _pad('${micros.toStringAsFixed(1)}µs', 11);
