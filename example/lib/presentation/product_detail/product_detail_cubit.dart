import 'package:basalt_example/domain/repositories/product_repository.dart';
import 'package:basalt_example/domain/repositories/review_repository.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:basalt_example/presentation/product_detail/product_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads a product with its reviews/rating and lets the shopper add a review.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit(this._products, this._reviews, this.productId)
      : super(const ProductDetailState());

  final ProductRepository _products;
  final ReviewRepository _reviews;
  final int productId;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final data = await _products.detail(productId);
      if (data == null) {
        emit(state.copyWith(
          status: LoadStatus.failure,
          error: 'Product not found',
        ));
        return;
      }
      emit(state.copyWith(status: LoadStatus.success, data: data));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: '$e'));
    }
  }

  /// Adds a review by [customerId] and reloads so the new rating/count show.
  Future<void> addReview({
    required int customerId,
    required int rating,
    String? comment,
  }) async {
    emit(state.copyWith(submitting: true));
    try {
      await _reviews.add(
        productId: productId,
        customerId: customerId,
        rating: rating,
        comment: comment,
      );
      final data = await _products.detail(productId);
      emit(state.copyWith(submitting: false, data: data));
    } catch (e) {
      emit(state.copyWith(submitting: false, error: '$e'));
    }
  }
}
