import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/address_mapper.dart';
import 'package:basalt_example/data/mappers/customer_mapper.dart';
import 'package:basalt_example/data/mappers/order_mapper.dart';
import 'package:basalt_example/data/models/address_row.dart';
import 'package:basalt_example/data/models/customer_row.dart';
import 'package:basalt_example/data/models/order_row.dart';
import 'package:basalt_example/data/repositories/order_items_loader.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/views/customer_profile.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';
import 'package:basalt_example/domain/repositories/customer_repository.dart';

/// SQLite-backed [CustomerRepository].
class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._db);

  final Connection _db;

  @override
  Future<List<Customer>> all() async {
    final rows = await _db.fetch(
      from(Customers.table)
          .orderBy(Customers.name.asc())
          .map(customerRowMapper.read),
    );
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<CustomerProfile?> profile(int id) async {
    final customer = await findCustomerRow(id).optional(_db);
    if (customer == null) return null;

    // One-to-many: addresses, loaded (and grouped) in a single query.
    final addressesByCustomer = await loadGroupedByFk(
      _db,
      Addresses.table,
      Addresses.customerId,
      [id],
      addressRowMapper.read,
    );
    final addresses = [
      for (final row in addressesByCustomer[id] ?? const <AddressRow>[])
        row.toDomain(),
    ];

    // Orders + their line items (batched, no N+1).
    final orderRows = await orderRowQuery
        .where(Orders.customerId.eq(id))
        .orderBy(Orders.createdAt.desc())
        .load(_db);
    final itemsByOrder =
        await loadOrderItemsByOrder(_db, [for (final o in orderRows) o.id]);
    final orders = [
      for (final order in orderRows)
        OrderSummary(
          order: order.toDomain(),
          items: itemsByOrder[order.id] ?? const [],
        ),
    ];

    return CustomerProfile(
      customer: customer.toDomain(),
      addresses: addresses,
      orders: orders,
    );
  }
}
