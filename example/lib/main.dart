import 'package:basalt_example/app.dart';
import 'package:basalt_example/core/backend/basalt_backend.dart';
import 'package:basalt_example/core/di/injector.dart';
import 'package:flutter/material.dart';

/// Default entrypoint — runs the shop on the **basalt** backend.
///
/// For the parallel **drift** backend (its own, separate database instance),
/// launch `lib/main_drift.dart` instead:
/// `flutter run -t lib/main_drift.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the basalt database (migrate + seed on first run) and wire the service
  // locator with its repositories.
  await configureDependencies(BasaltBackend());

  runApp(const ShopApp());
}
