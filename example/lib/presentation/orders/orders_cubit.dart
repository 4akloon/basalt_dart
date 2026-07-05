import 'package:basalt_example/domain/repositories/order_repository.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/orders/orders_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the orders list.
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._orders) : super(const OrdersState());

  final OrderRepository _orders;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final orders = await _orders.recent();
      emit(state.copyWith(status: LoadStatus.success, orders: orders));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: '$e'));
    }
  }
}
