import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/views/customer_profile.dart';

/// Read access to customers and their profiles.
abstract interface class CustomerRepository {
  /// Every customer.
  Future<List<Customer>> all();

  /// A customer with their addresses and orders, or null if not found.
  Future<CustomerProfile?> profile(int id);
}
