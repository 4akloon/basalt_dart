import 'package:basalt_example/core/database/drift/shop_drift_database.dart';
import 'package:basalt_example/domain/repositories/review_repository.dart';
import 'package:drift/drift.dart';

/// Drift-backed [ReviewRepository].
class DriftReviewRepository implements ReviewRepository {
  DriftReviewRepository(this._db);

  final ShopDriftDatabase _db;

  @override
  Future<void> add({
    required int productId,
    required int customerId,
    required int rating,
    String? comment,
  }) async {
    await _db.managers.reviews.create(
      (o) => o(
        productId: productId,
        customerId: customerId,
        rating: rating,
        comment: Value(comment),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
