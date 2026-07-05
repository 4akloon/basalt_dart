/// Write access to product reviews (reads happen via `ProductRepository.detail`).
abstract interface class ReviewRepository {
  /// Adds a review for [productId] by [customerId] (rating 1..5, optional
  /// comment).
  Future<void> add({
    required int productId,
    required int customerId,
    required int rating,
    String? comment,
  });
}
