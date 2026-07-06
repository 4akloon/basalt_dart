import 'package:basalt/basalt.dart';
import 'package:basalt_example/data/repositories/product_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_database.dart';

void main() {
  late Connection db;
  late ProductRepositoryImpl products;

  setUp(() async {
    db = await openTestDatabase();
    products = ProductRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('detail() loads the product with its category, reviews and rating',
      () async {
    // Product #1 (Laptop Pro 14) has two seeded reviews: 5 and 4 stars.
    final detail = await products.detail(1);

    expect(detail, isNotNull);
    expect(detail!.product.name, 'Laptop Pro 14');
    // Belongs-to relation resolved.
    expect(detail.product.category?.name, 'Computers');
    // Aggregate over reviews.
    expect(detail.reviewCount, 2);
    expect(detail.averageRating, closeTo(4.5, 0.001));
    // Individual reviews each carry their author (a nested relation).
    expect(detail.reviews, hasLength(2));
    expect(
      detail.reviews.map((r) => r.customer?.name),
      containsAll(<String>['Alice Johnson', 'Bob Smith']),
    );
  });

  test('detail() returns null for a missing product', () async {
    expect(await products.detail(9999), isNull);
  });

  test('list() filters by category and search', () async {
    // Category #3 is "Phones" — two seeded products.
    final phones = await products.list(categoryId: 3);
    expect(phones.map((p) => p.name),
        containsAll(['Smartphone X', 'Smartphone Mini']));
    expect(phones.every((p) => p.categoryId == 3), isTrue);

    final search = await products.list(search: 'laptop');
    expect(search, hasLength(2));
    expect(
        search.every((p) => p.name.toLowerCase().contains('laptop')), isTrue);
  });

  test('list() round-trips the JSON metadata column via the custom SqlType',
      () async {
    final all = await products.list();

    // Seeded with a JSON map — decoded back into a real Map by
    // JsonMapOrNullSqlType (configured for products.metadata in basalt.yaml).
    final laptop = all.firstWhere((p) => p.name == 'Laptop Pro 14');
    expect(laptop.metadata, isNotNull);
    expect(laptop.metadata!['warranty'], '2 years');
    expect(laptop.metadata!['ports'], ['USB-C', 'HDMI']);

    // Seeded without metadata → reads back as null.
    final mini = all.firstWhere((p) => p.name == 'Smartphone Mini');
    expect(mini.metadata, isNull);
  });
}
