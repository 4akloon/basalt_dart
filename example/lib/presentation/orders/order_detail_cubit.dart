import 'package:basalt_example/domain/entities/order_status.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/orders/order_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads one order with its line items and lets the operator change its status.
class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit(this._orders, this.orderId)
      : super(const OrderDetailState());

  final OrderRepository _orders;
  final int orderId;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final summary = await _orders.detail(orderId);
      if (summary == null) {
        emit(state.copyWith(status: LoadStatus.failure, error: 'Order not found'));
        return;
      }
      emit(state.copyWith(status: LoadStatus.success, summary: summary));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: '$e'));
    }
  }

  Future<void> changeStatus(OrderStatus status) async {
    emit(state.copyWith(updating: true));
    try {
      await _orders.updateStatus(orderId, status);
      final summary = await _orders.detail(orderId);
      emit(state.copyWith(updating: false, summary: summary));
    } catch (e) {
      emit(state.copyWith(updating: false, error: '$e'));
    }
  }
}
