import 'package:basalt_example/domain/entities/views/order_summary.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:equatable/equatable.dart';

/// State for the orders list.
class OrdersState extends Equatable {
  const OrdersState({
    this.status = LoadStatus.initial,
    this.orders = const [],
    this.error,
  });

  final LoadStatus status;
  final List<OrderSummary> orders;
  final String? error;

  OrdersState copyWith({
    LoadStatus? status,
    List<OrderSummary>? orders,
    String? error,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, orders, error];
}
