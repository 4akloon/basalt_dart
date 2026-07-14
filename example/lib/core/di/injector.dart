import 'package:basalt_example/core/backend/app_backend.dart';
import 'package:basalt_example/domain/repositories/analytics_repository.dart';
import 'package:basalt_example/domain/repositories/category_repository.dart';
import 'package:basalt_example/domain/repositories/customer_repository.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';
import 'package:basalt_example/domain/repositories/product_repository.dart';
import 'package:basalt_example/domain/repositories/review_repository.dart';
import 'package:get_it/get_it.dart';

/// Global service locator. Cubits resolve their repository interfaces from here;
/// the presentation layer never sees a concrete implementation, a driver, or
/// which backend ([AppBackend]) is actually running.
final getIt = GetIt.instance;

/// Opens [backend]'s database instance and registers it plus every repository
/// it serves. Call once at startup — the chosen [backend] (basalt or drift)
/// determines which implementations the whole app runs against.
Future<void> configureDependencies(AppBackend backend) async {
  await backend.open();
  getIt
    ..registerSingleton<AppBackend>(backend)
    ..registerLazySingleton<CategoryRepository>(
        () => backend.categoryRepository)
    ..registerLazySingleton<ProductRepository>(() => backend.productRepository)
    ..registerLazySingleton<CustomerRepository>(
        () => backend.customerRepository)
    ..registerLazySingleton<OrderRepository>(() => backend.orderRepository)
    ..registerLazySingleton<ReviewRepository>(() => backend.reviewRepository)
    ..registerLazySingleton<AnalyticsRepository>(
        () => backend.analyticsRepository);
}
