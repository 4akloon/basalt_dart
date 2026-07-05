import 'package:basalt/basalt.dart';
import 'package:basalt_example/data/models/review_write.dart';
import 'package:basalt_example/domain/repositories/review_repository.dart';

/// SQLite-backed [ReviewRepository].
class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._db);

  final Connection _db;

  @override
  Future<void> add({
    required int productId,
    required int customerId,
    required int rating,
    String? comment,
  }) async {
    await _db.execute(
      ReviewWrite(
        productId: productId,
        customerId: customerId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ).toInsert(),
    );
  }
}
