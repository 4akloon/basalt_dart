import 'package:basalt/basalt.dart';
import 'package:basalt_example/core/backend/app_backend.dart';
import 'package:basalt_example/core/database/app_database.dart';
import 'package:basalt_example/data/repositories/analytics_repository_impl.dart';
import 'package:basalt_example/data/repositories/category_repository_impl.dart';
import 'package:basalt_example/data/repositories/customer_repository_impl.dart';
import 'package:basalt_example/data/repositories/order_repository_impl.dart';
import 'package:basalt_example/data/repositories/product_repository_impl.dart';
import 'package:basalt_example/data/repositories/review_repository_impl.dart';
import 'package:basalt_example/domain/repositories/analytics_repository.dart';
import 'package:basalt_example/domain/repositories/category_repository.dart';
import 'package:basalt_example/domain/repositories/customer_repository.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';
import 'package:basalt_example/domain/repositories/product_repository.dart';
import 'package:basalt_example/domain/repositories/review_repository.dart';

/// [AppBackend] powered by **basalt** (+ its SQLite backend). This is the
/// default backend, launched from `lib/main.dart`. It owns the `basalt_shop.db`
/// instance and serves every repository from the `basalt`-based implementations
/// under `data/repositories/`.
class BasaltBackend implements AppBackend {
  @override
  String get label => 'Basalt';

  late final Connection _db;

  /// The open basalt [Connection]. Exposed so the debug entrypoint can hand it
  /// to the Basalt DevTools inspector.
  Connection get connection => _db;

  @override
  Future<void> open() async {
    _db = await AppDatabase.open();
  }

  @override
  Future<void> reset() => AppDatabase.reset(_db);

  @override
  late final CategoryRepository categoryRepository =
      CategoryRepositoryImpl(_db);

  @override
  late final ProductRepository productRepository = ProductRepositoryImpl(_db);

  @override
  late final CustomerRepository customerRepository =
      CustomerRepositoryImpl(_db);

  @override
  late final OrderRepository orderRepository = OrderRepositoryImpl(_db);

  @override
  late final ReviewRepository reviewRepository = ReviewRepositoryImpl(_db);

  @override
  late final AnalyticsRepository analyticsRepository =
      AnalyticsRepositoryImpl(_db);
}
