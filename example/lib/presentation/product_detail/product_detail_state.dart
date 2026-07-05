import 'package:basalt_example/domain/entities/views/product_with_stats.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:equatable/equatable.dart';

/// State for the product-detail screen.
class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = LoadStatus.initial,
    this.data,
    this.error,
    this.submitting = false,
  });

  final LoadStatus status;
  final ProductWithStats? data;
  final String? error;
  final bool submitting;

  ProductDetailState copyWith({
    LoadStatus? status,
    ProductWithStats? data,
    String? error,
    bool? submitting,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [status, data, error, submitting];
}
