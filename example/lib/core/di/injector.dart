import 'package:basalt/basalt.dart';
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
import 'package:get_it/get_it.dart';

/// Global service locator. Cubits resolve their repository interfaces from here;
/// the presentation layer never sees a concrete implementation or `basalt`.
final getIt = GetIt.instance;

/// Registers the open [db] and every repository. Call once, after the database
/// is opened.
void configureDependencies(Connection db) {
  getIt
    ..registerSingleton<Connection>(db)
    ..registerLazySingleton<CategoryRepository>(
        () => CategoryRepositoryImpl(getIt()))
    ..registerLazySingleton<ProductRepository>(
        () => ProductRepositoryImpl(getIt()))
    ..registerLazySingleton<CustomerRepository>(
        () => CustomerRepositoryImpl(getIt()))
    ..registerLazySingleton<OrderRepository>(
        () => OrderRepositoryImpl(getIt()))
    ..registerLazySingleton<ReviewRepository>(
        () => ReviewRepositoryImpl(getIt()))
    ..registerLazySingleton<AnalyticsRepository>(
        () => AnalyticsRepositoryImpl(getIt()));
}
