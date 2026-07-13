import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/data/repositories/drift/drift_mappers.dart';
import 'package:basalt_example/data/repositories/drift/drift_order_loader.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/views/customer_profile.dart';
import 'package:basalt_example/domain/repositories/customer_repository.dart';
import 'package:drift/drift.dart';

/// Drift-backed [CustomerRepository], using drift's generated manager API.
class DriftCustomerRepository implements CustomerRepository {
  DriftCustomerRepository(this._db);

  final ShopDriftDatabase _db;

  @override
  Future<List<Customer>> all() async {
    // Core select (not the manager API) — the same single "SELECT ... ORDER BY
    // name" that basalt issues, so the two are compared on equal footing.
    final rows = await (_db.select(_db.customers)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return [for (final c in rows) customerToDomain(c)];
  }

  @override
  Future<CustomerProfile?> profile(int id) async {
    final customer = await _db.managers.customers
        .filter((f) => f.id.equals(id))
        .getSingleOrNull();
    if (customer == null) return null;

    final addresses = await _db.managers.addresses
        .filter((f) => f.customerId.id.equals(id))
        .get();
    final orders = await loadCustomerOrders(_db, id);

    return CustomerProfile(
      customer: customerToDomain(customer),
      addresses: [for (final a in addresses) addressToDomain(a)],
      orders: orders,
    );
  }
}
