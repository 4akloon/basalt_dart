import 'package:basalt_example/domain/entities/views/analytics.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:equatable/equatable.dart';

/// State for the analytics dashboard.
class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.status = LoadStatus.initial,
    this.revenueByCategory = const [],
    this.topCustomers = const [],
    this.lowStock = const [],
    this.error,
  });

  final LoadStatus status;
  final List<CategoryRevenue> revenueByCategory;
  final List<TopCustomer> topCustomers;
  final List<LowStockProduct> lowStock;
  final String? error;

  AnalyticsState copyWith({
    LoadStatus? status,
    List<CategoryRevenue>? revenueByCategory,
    List<TopCustomer>? topCustomers,
    List<LowStockProduct>? lowStock,
    String? error,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      revenueByCategory: revenueByCategory ?? this.revenueByCategory,
      topCustomers: topCustomers ?? this.topCustomers,
      lowStock: lowStock ?? this.lowStock,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, revenueByCategory, topCustomers, lowStock, error];
}
