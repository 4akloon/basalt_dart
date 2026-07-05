import 'package:basalt_example/domain/entities/views/order_summary.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:equatable/equatable.dart';

/// State for a single order's detail screen.
class OrderDetailState extends Equatable {
  const OrderDetailState({
    this.status = LoadStatus.initial,
    this.summary,
    this.error,
    this.updating = false,
  });

  final LoadStatus status;
  final OrderSummary? summary;
  final String? error;
  final bool updating;

  OrderDetailState copyWith({
    LoadStatus? status,
    OrderSummary? summary,
    String? error,
    bool? updating,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      error: error,
      updating: updating ?? this.updating,
    );
  }

  @override
  List<Object?> get props => [status, summary, error, updating];
}
