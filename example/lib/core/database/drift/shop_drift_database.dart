import 'dart:convert';

import 'package:drift/drift.dart';

part 'shop_drift_database.g.dart';

/// The **drift** schema — the second, independent database backing the shop.
///
/// It deliberately mirrors, table for table, the basalt schema in
/// `core/database/schema.dart` (which is itself generated from the SQL
/// migrations under `migrations/`), so the two backends store the *same shape*
/// of data in *separate* database files. Where basalt splits reads/writes into
/// annotated model classes and generates query objects, drift generates a data
/// class + companion per table from these `Table` declarations.

/// Stores a JSON object (`Map<String, Object?>`) in a `TEXT` column — drift's
/// equivalent of the app's `JsonMapSqlType` basalt codec. Powers
/// `products.metadata`.
class JsonMapConverter extends TypeConverter<Map<String, Object?>, String> {
  const JsonMapConverter();

  @override
  Map<String, Object?> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as Map).cast<String, Object?>();

  @override
  String toSql(Map<String, Object?> value) => jsonEncode(value);
}

/// Product categories, organised as a self-referential tree (`parentId` is null
/// for top-level roots).
@DataClassName('DriftCategory')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get parentId =>
      integer().nullable().references(Categories, #id)();
}

/// Shop customers. `loyaltyTier` is a text enum and `createdAt` is epoch millis.
@DataClassName('DriftCustomer')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get loyaltyTier =>
      text().withDefault(const Constant('bronze'))();
  IntColumn get createdAt => integer()();
}

/// Delivery addresses. Many belong to one customer.
@DataClassName('DriftAddress')
class Addresses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  TextColumn get label => text()();
  TextColumn get city => text()();
  TextColumn get street => text()();
}

/// Catalogue products. `isActive` is a 0/1 int (SQLite has no boolean) and
/// `metadata` is free-form JSON via [JsonMapConverter].
@DataClassName('DriftProduct')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  RealColumn get price => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  TextColumn get metadata =>
      text().map(const JsonMapConverter()).nullable()();
}

/// Customer orders. `status` is a text enum, `shippingAddressId` is a nullable
/// FK, `createdAt` is epoch millis.
@DataClassName('DriftOrder')
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get shippingAddressId =>
      integer().nullable().references(Addresses, #id)();
  IntColumn get createdAt => integer()();
}

/// Line items — the orders↔products junction. `unitPrice` snapshots the price
/// at purchase time.
@DataClassName('DriftOrderItem')
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
}

/// Product reviews (1..5 stars). Belongs to both a product and a customer.
@DataClassName('DriftReview')
class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get rating => integer()();
  TextColumn get comment => text().nullable()();
  IntColumn get createdAt => integer()();
}

/// The drift database. Its tables mirror the basalt schema so both backends
/// serve identical domain data from their own, separate instances. The
/// aggregate reads live in `queries.drift` and are generated onto this class as
/// typed methods (`revenueByCategory()`, `topCustomers()`, …).
@DriftDatabase(
  tables: [Categories, Customers, Addresses, Products, Orders, OrderItems, Reviews],
  include: {'queries.drift'},
)
class ShopDriftDatabase extends _$ShopDriftDatabase {
  ShopDriftDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
