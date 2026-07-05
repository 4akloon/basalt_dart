import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/models/address_write.dart';
import 'package:basalt_example/data/models/category_write.dart';
import 'package:basalt_example/data/models/customer_row.dart';
import 'package:basalt_example/data/models/order_item_write.dart';
import 'package:basalt_example/data/models/order_write.dart';
import 'package:basalt_example/data/models/product_write.dart';
import 'package:basalt_example/data/models/review_write.dart';

/// Populates the database with a demo catalogue, customers, orders and reviews.
///
/// Only runs when the database is empty (see [isEmpty]); the whole seed is a
/// single transaction. Rows are inserted with the generated `toInsert()` derives
/// (the write models), so the primary keys **autoincrement** — the ids referenced
/// by the foreign keys below (`1..N`) line up because rows are inserted in id
/// order per table.
class SeedData {
  const SeedData._();

  /// True when there are no customers yet — used to decide whether to seed.
  static Future<bool> isEmpty(Connection db) async {
    final total = countAll();
    final rows = await db.fetch(
      from(Customers.table).select([total]).map((r) => r.get(total)),
    );
    return rows.single == 0;
  }

  /// Inserts the demo data in one transaction.
  static Future<void> run(Connection db) async {
    final now = DateTime.now();
    int daysAgo(int d) =>
        now.subtract(Duration(days: d)).millisecondsSinceEpoch;

    await db.transaction((tx) async {
      // ---- Categories (a small tree) --------------------------------------
      for (final (name, parent) in const [
        ('Electronics', null),
        ('Computers', 1),
        ('Phones', 1),
        ('Home', null),
        ('Kitchen', 4),
      ]) {
        await tx.execute(CategoryWrite(name: name, parentId: parent).toInsert());
      }

      // ---- Products -------------------------------------------------------
      for (final (name, desc, price, stock, cat) in const [
        ('Laptop Pro 14', 'Powerful 14-inch laptop', 1999.0, 8, 2),
        ('Laptop Air 13', 'Thin and light ultrabook', 1299.0, 3, 2),
        ('Smartphone X', 'Flagship smartphone', 999.0, 20, 3),
        ('Smartphone Mini', 'Compact and affordable', 699.0, 2, 3),
        ('Wireless Earbuds', 'Noise-cancelling earbuds', 149.0, 50, 1),
        ('4K Monitor', '27-inch 4K display', 449.0, 5, 2),
        ('Espresso Machine', 'Barista-grade espresso', 599.0, 4, 5),
        ('Blender Pro', 'High-speed blender', 129.0, 15, 5),
        ('Smart Speaker', 'Voice-assistant speaker', 99.0, 0, 1),
        ('Air Fryer', 'Oil-free air fryer', 179.0, 6, 5),
      ]) {
        await tx.execute(
          ProductWrite(
            name: name,
            description: desc,
            price: price,
            stock: stock,
            categoryId: cat,
            isActive: 1,
          ).toInsert(),
        );
      }

      // ---- Customers (the combined all-in-one model) ----------------------
      // `CustomerRow` carries all three derives; its `toInsert()` omits the
      // readOnly id, so these also autoincrement.
      for (final (id, name, email, tier, days) in const [
        (1, 'Alice Johnson', 'alice@example.com', 'gold', 400),
        (2, 'Bob Smith', 'bob@example.com', 'silver', 200),
        (3, 'Carol Davis', 'carol@example.com', 'bronze', 90),
        (4, 'Dave Wilson', 'dave@example.com', 'silver', 30),
      ]) {
        await tx.execute(
          CustomerRow(
            id: id,
            name: name,
            email: email,
            loyaltyTier: tier,
            createdAt: daysAgo(days),
          ).toInsert(),
        );
      }

      // ---- Addresses ------------------------------------------------------
      for (final (customer, label, city, street) in const [
        (1, 'Home', 'Kyiv', '12 Khreshchatyk St'),
        (1, 'Work', 'Kyiv', '5 Business Ave'),
        (2, 'Home', 'Lviv', '8 Rynok Sq'),
        (3, 'Home', 'Odesa', '20 Deribasivska St'),
      ]) {
        await tx.execute(
          AddressWrite(
            customerId: customer,
            label: label,
            city: city,
            street: street,
          ).toInsert(),
        );
      }

      // ---- Orders ---------------------------------------------------------
      for (final (customer, status, address, days) in const [
        (1, 'delivered', 1, 60),
        (1, 'shipped', 2, 10),
        (2, 'paid', 3, 5),
        (3, 'pending', 4, 1),
        (4, 'pending', null, 0),
      ]) {
        await tx.execute(
          OrderWrite(
            customerId: customer,
            status: status,
            shippingAddressId: address,
            createdAt: daysAgo(days),
          ).toInsert(),
        );
      }

      // ---- Order items ----------------------------------------------------
      for (final (order, product, qty, price) in const [
        (1, 1, 1, 1999.0),
        (1, 5, 2, 149.0),
        (2, 3, 1, 999.0),
        (3, 7, 1, 599.0),
        (3, 8, 2, 129.0),
        (4, 2, 1, 1299.0),
        (5, 5, 1, 149.0),
        (5, 10, 1, 179.0),
      ]) {
        await tx.execute(
          OrderItemWrite(
            orderId: order,
            productId: product,
            quantity: qty,
            unitPrice: price,
          ).toInsert(),
        );
      }

      // ---- Reviews --------------------------------------------------------
      for (final (product, customer, rating, comment, days) in const [
        (1, 1, 5, 'Blazing fast, love it', 50),
        (1, 2, 4, 'Great but pricey', 40),
        (3, 2, 5, 'Best phone I have owned', 20),
        (3, 1, 4, null, 15),
        (5, 3, 3, 'Decent sound for the price', 8),
        (7, 1, 5, 'Perfect espresso every morning', 30),
      ]) {
        await tx.execute(
          ReviewWrite(
            productId: product,
            customerId: customer,
            rating: rating,
            comment: comment,
            createdAt: daysAgo(days),
          ).toInsert(),
        );
      }
    });
  }
}
