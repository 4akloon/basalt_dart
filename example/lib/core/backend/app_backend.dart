import 'package:basalt_example/domain/repositories/analytics_repository.dart';
import 'package:basalt_example/domain/repositories/category_repository.dart';
import 'package:basalt_example/domain/repositories/customer_repository.dart';
import 'package:basalt_example/domain/repositories/order_repository.dart';
import 'package:basalt_example/domain/repositories/product_repository.dart';
import 'package:basalt_example/domain/repositories/review_repository.dart';

/// A complete database backend for the shop: it owns a database instance and
/// exposes one implementation of every domain repository against it.
///
/// The app ships two of these — a `basalt` one and a `drift` one — each with its
/// **own, separate** on-device database file. They are *not* interchangeable at
/// runtime: you pick one at startup by launching the matching entrypoint
/// (`lib/main.dart` for basalt, `lib/main_drift.dart` for drift). The rest of
/// the app (cubits, pages, DI) only ever sees these repository interfaces, so it
/// is identical regardless of which backend is running — which is exactly what
/// makes the two a fair, live side-by-side comparison.
abstract interface class AppBackend {
  /// Human-readable name of the backend, shown as a corner ribbon so you can
  /// tell the two running instances apart (e.g. `Basalt` / `Drift`).
  String get label;

  /// Opens (creating + migrating + seeding on first run) this backend's
  /// database instance. Call once, before resolving any repository.
  Future<void> open();

  /// **Dev-only.** Wipes and re-seeds the demo data in this backend's instance.
  /// Backs the debug "Reset & reseed" action.
  Future<void> reset();

  /// Read/write access to the category tree.
  CategoryRepository get categoryRepository;

  /// Read access to the product catalogue.
  ProductRepository get productRepository;

  /// Read access to customers and their profiles.
  CustomerRepository get customerRepository;

  /// Order placement and history.
  OrderRepository get orderRepository;

  /// Product reviews.
  ReviewRepository get reviewRepository;

  /// Raw-SQL powered analytics.
  AnalyticsRepository get analyticsRepository;
}
