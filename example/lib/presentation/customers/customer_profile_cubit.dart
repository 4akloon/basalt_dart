import 'package:basalt_example/domain/repositories/customer_repository.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/customers/customer_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads a customer's profile (addresses + orders).
class CustomerProfileCubit extends Cubit<CustomerProfileState> {
  CustomerProfileCubit(this._customers, this.customerId)
      : super(const CustomerProfileState());

  final CustomerRepository _customers;
  final int customerId;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final profile = await _customers.profile(customerId);
      if (profile == null) {
        emit(state.copyWith(
          status: LoadStatus.failure,
          error: 'Customer not found',
        ));
        return;
      }
      emit(state.copyWith(status: LoadStatus.success, profile: profile));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: '$e'));
    }
  }
}
