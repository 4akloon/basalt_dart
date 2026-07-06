import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/database/schema.dart';
import 'package:basalt_example/data/mappers/customer_mapper.dart';
import 'package:basalt_example/data/mappers/customer_profile_mapper.dart';
import 'package:basalt_example/data/models/customer_profile_row.dart';
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
    final row = await CustomerProfileRowQuery().findBy(Customers.id, id).optional(_db);
    return row?.toDomain();
  }
}
