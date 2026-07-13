import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:drift/drift.dart';

/// Seeds the drift database with the exact same demo catalogue, customers,
/// orders and reviews as the basalt `SeedData`.
///
/// Rows are inserted in id order inside one batch, and every primary key is
/// `autoIncrement`, so the ids come out `1..N` — which is why the `1..N`
/// foreign keys below line up, identical to the basalt seed. The two backends
/// therefore hold byte-for-byte equivalent data in their separate files.
class DriftSeed {
  const DriftSeed._();

  /// True when there are no customers yet — mirrors `SeedData.isEmpty`.
  static Future<bool> isEmpty(ShopDriftDatabase db) async {
    final total = db.customers.id.count();
    final row = await (db.selectOnly(db.customers)..addColumns([total]))
        .getSingle();
    return (row.read(total) ?? 0) == 0;
  }

  /// Inserts the demo data in one batch (a single transaction).
  static Future<void> run(ShopDriftDatabase db) async {
    final now = DateTime.now();
    int daysAgo(int d) =>
        now.subtract(Duration(days: d)).millisecondsSinceEpoch;

    await db.batch((b) {
      // ---- Categories (a small tree) ------------------------------------
      b.insertAll(db.categories, const [
        CategoriesCompanion(name: Value('Electronics')),
        CategoriesCompanion(name: Value('Computers'), parentId: Value(1)),
        CategoriesCompanion(name: Value('Phones'), parentId: Value(1)),
        CategoriesCompanion(name: Value('Home')),
        CategoriesCompanion(name: Value('Kitchen'), parentId: Value(4)),
      ]);

      // ---- Products -----------------------------------------------------
      b.insertAll(db.products, [
        ProductsCompanion.insert(
          name: 'Laptop Pro 14',
          description: 'Powerful 14-inch laptop',
          price: 1999.0,
          stock: const Value(8),
          categoryId: 2,
          metadata: const Value({
            'warranty': '2 years',
            'ports': ['USB-C', 'HDMI'],
          }),
        ),
        ProductsCompanion.insert(
          name: 'Laptop Air 13',
          description: 'Thin and light ultrabook',
          price: 1299.0,
          stock: const Value(3),
          categoryId: 2,
        ),
        ProductsCompanion.insert(
          name: 'Smartphone X',
          description: 'Flagship smartphone',
          price: 999.0,
          stock: const Value(20),
          categoryId: 3,
        ),
        ProductsCompanion.insert(
          name: 'Smartphone Mini',
          description: 'Compact and affordable',
          price: 699.0,
          stock: const Value(2),
          categoryId: 3,
        ),
        ProductsCompanion.insert(
          name: 'Wireless Earbuds',
          description: 'Noise-cancelling earbuds',
          price: 149.0,
          stock: const Value(50),
          categoryId: 1,
          metadata: const Value({'batteryHours': 8, 'wireless': true}),
        ),
        ProductsCompanion.insert(
          name: '4K Monitor',
          description: '27-inch 4K display',
          price: 449.0,
          stock: const Value(5),
          categoryId: 2,
        ),
        ProductsCompanion.insert(
          name: 'Espresso Machine',
          description: 'Barista-grade espresso',
          price: 599.0,
          stock: const Value(4),
          categoryId: 5,
        ),
        ProductsCompanion.insert(
          name: 'Blender Pro',
          description: 'High-speed blender',
          price: 129.0,
          stock: const Value(15),
          categoryId: 5,
        ),
        ProductsCompanion.insert(
          name: 'Smart Speaker',
          description: 'Voice-assistant speaker',
          price: 99.0,
          stock: const Value(0),
          categoryId: 1,
        ),
        ProductsCompanion.insert(
          name: 'Air Fryer',
          description: 'Oil-free air fryer',
          price: 179.0,
          stock: const Value(6),
          categoryId: 5,
        ),
      ]);

      // ---- Customers ----------------------------------------------------
      b.insertAll(db.customers, [
        CustomersCompanion.insert(
          name: 'Alice Johnson',
          email: 'alice@example.com',
          loyaltyTier: const Value('gold'),
          createdAt: daysAgo(400),
        ),
        CustomersCompanion.insert(
          name: 'Bob Smith',
          email: 'bob@example.com',
          loyaltyTier: const Value('silver'),
          createdAt: daysAgo(200),
        ),
        CustomersCompanion.insert(
          name: 'Carol Davis',
          email: 'carol@example.com',
          loyaltyTier: const Value('bronze'),
          createdAt: daysAgo(90),
        ),
        CustomersCompanion.insert(
          name: 'Dave Wilson',
          email: 'dave@example.com',
          loyaltyTier: const Value('silver'),
          createdAt: daysAgo(30),
        ),
      ]);

      // ---- Addresses ----------------------------------------------------
      b.insertAll(db.addresses, const [
        AddressesCompanion(
          customerId: Value(1),
          label: Value('Home'),
          city: Value('Kyiv'),
          street: Value('12 Khreshchatyk St'),
        ),
        AddressesCompanion(
          customerId: Value(1),
          label: Value('Work'),
          city: Value('Kyiv'),
          street: Value('5 Business Ave'),
        ),
        AddressesCompanion(
          customerId: Value(2),
          label: Value('Home'),
          city: Value('Lviv'),
          street: Value('8 Rynok Sq'),
        ),
        AddressesCompanion(
          customerId: Value(3),
          label: Value('Home'),
          city: Value('Odesa'),
          street: Value('20 Deribasivska St'),
        ),
      ]);

      // ---- Orders -------------------------------------------------------
      b.insertAll(db.orders, [
        OrdersCompanion.insert(
          customerId: 1,
          status: const Value('delivered'),
          shippingAddressId: const Value(1),
          createdAt: daysAgo(60),
        ),
        OrdersCompanion.insert(
          customerId: 1,
          status: const Value('shipped'),
          shippingAddressId: const Value(2),
          createdAt: daysAgo(10),
        ),
        OrdersCompanion.insert(
          customerId: 2,
          status: const Value('paid'),
          shippingAddressId: const Value(3),
          createdAt: daysAgo(5),
        ),
        OrdersCompanion.insert(
          customerId: 3,
          status: const Value('pending'),
          shippingAddressId: const Value(4),
          createdAt: daysAgo(1),
        ),
        OrdersCompanion.insert(
          customerId: 4,
          status: const Value('pending'),
          createdAt: daysAgo(0),
        ),
      ]);

      // ---- Order items --------------------------------------------------
      b.insertAll(db.orderItems, const [
        OrderItemsCompanion(
            orderId: Value(1),
            productId: Value(1),
            quantity: Value(1),
            unitPrice: Value(1999.0)),
        OrderItemsCompanion(
            orderId: Value(1),
            productId: Value(5),
            quantity: Value(2),
            unitPrice: Value(149.0)),
        OrderItemsCompanion(
            orderId: Value(2),
            productId: Value(3),
            quantity: Value(1),
            unitPrice: Value(999.0)),
        OrderItemsCompanion(
            orderId: Value(3),
            productId: Value(7),
            quantity: Value(1),
            unitPrice: Value(599.0)),
        OrderItemsCompanion(
            orderId: Value(3),
            productId: Value(8),
            quantity: Value(2),
            unitPrice: Value(129.0)),
        OrderItemsCompanion(
            orderId: Value(4),
            productId: Value(2),
            quantity: Value(1),
            unitPrice: Value(1299.0)),
        OrderItemsCompanion(
            orderId: Value(5),
            productId: Value(5),
            quantity: Value(1),
            unitPrice: Value(149.0)),
        OrderItemsCompanion(
            orderId: Value(5),
            productId: Value(10),
            quantity: Value(1),
            unitPrice: Value(179.0)),
      ]);

      // ---- Reviews ------------------------------------------------------
      b.insertAll(db.reviews, [
        ReviewsCompanion.insert(
            productId: 1,
            customerId: 1,
            rating: 5,
            comment: const Value('Blazing fast, love it'),
            createdAt: daysAgo(50)),
        ReviewsCompanion.insert(
            productId: 1,
            customerId: 2,
            rating: 4,
            comment: const Value('Great but pricey'),
            createdAt: daysAgo(40)),
        ReviewsCompanion.insert(
            productId: 3,
            customerId: 2,
            rating: 5,
            comment: const Value('Best phone I have owned'),
            createdAt: daysAgo(20)),
        ReviewsCompanion.insert(
            productId: 3, customerId: 1, rating: 4, createdAt: daysAgo(15)),
        ReviewsCompanion.insert(
            productId: 5,
            customerId: 3,
            rating: 3,
            comment: const Value('Decent sound for the price'),
            createdAt: daysAgo(8)),
        ReviewsCompanion.insert(
            productId: 7,
            customerId: 1,
            rating: 5,
            comment: const Value('Perfect espresso every morning'),
            createdAt: daysAgo(30)),
      ]);
    });
  }
}
