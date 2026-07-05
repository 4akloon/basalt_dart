import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:equatable/equatable.dart';

/// State for the customers list.
class CustomersState extends Equatable {
  const CustomersState({
    this.status = LoadStatus.initial,
    this.customers = const [],
    this.error,
  });

  final LoadStatus status;
  final List<Customer> customers;
  final String? error;

  CustomersState copyWith({
    LoadStatus? status,
    List<Customer>? customers,
    String? error,
  }) {
    return CustomersState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, customers, error];
}
