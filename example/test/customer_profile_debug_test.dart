import 'package:basalt_example/data/repositories/customer_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_database.dart';

void main() {
  test('profile loads seeded customers', () async {
    final db = await openTestDatabase();
    addTearDown(db.close);
    final repo = CustomerRepositoryImpl(db);

    for (final id in [1, 2, 3, 4]) {
      final profile = await repo.profile(id);
      expect(profile, isNotNull, reason: 'customer id=$id should exist');
    }
  });
}
