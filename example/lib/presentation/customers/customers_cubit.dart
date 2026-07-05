import 'package:basalt_example/domain/repositories/customer_repository.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/customers/customers_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the customers list.
class CustomersCubit extends Cubit<CustomersState> {
  CustomersCubit(this._customers) : super(const CustomersState());

  final CustomerRepository _customers;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final customers = await _customers.all();
      emit(state.copyWith(status: LoadStatus.success, customers: customers));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: '$e'));
    }
  }
}
