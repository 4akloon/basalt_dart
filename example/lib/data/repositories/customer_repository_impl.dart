import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/address_mapper.dart';
import 'package:basalt_example/data/mappers/customer_mapper.dart';
import 'package:basalt_example/data/mappers/customer_order_mapper.dart';
import 'package:basalt_example/data/models/address_row.dart';
import 'package:basalt_example/data/models/customer_order_row.dart';
import 'package:basalt_example/data/models/customer_row.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/views/customer_profile.dart';
import 'package:basalt_example/domain/repositories/customer_repository.dart';

/// SQLite-backed [CustomerRepository].
class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._db);

  final Connection _db;

  @override
  Future<List<Customer>> all() async {
    final rows = await CustomerRowQuery().orderBy(Customers.name.asc()).load(_db);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<CustomerProfile?> profile(int id) async {
    // Load the two child collections in *separate* queries instead of one
    // `CustomerProfileRow` fold. A single query would join the two independent
    // one-to-manys (addresses × orders × items) into a cartesian product and
    // re-join the profile's own customer once per child; splitting keeps each
    // read linear. Addresses are read straight off their table (no `customer`
    // self-join), orders reuse `OrderRowQuery` (its own items fold).
    final customer =
        await CustomerRowQuery().findBy(Customers.id, id).optional(_db);
    if (customer == null) return null;

    final addresses = await from(Addresses.table)
        .where(Addresses.customerId.eq(id))
        .mapWith(AddressRowQuery.mapper)
        .load(_db);
    final orders = await CustomerOrderRowQuery()
        .filter(Orders.customerId.eq(id))
        .load(_db);

    return CustomerProfile(
      customer: customer.toDomain(),
      addresses: [for (final a in addresses) a.toDomain()],
      orders: [for (final o in orders) o.toDomain()],
    );
  }
}
