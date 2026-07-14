import 'package:basalt_example/app.dart';
import 'package:basalt_example/core/backend/drift_backend.dart';
import 'package:basalt_example/core/di/injector.dart';
import 'package:flutter/material.dart';

/// Parallel entrypoint — runs the *same* shop UI on the **drift** backend,
/// against its own separate database instance (`drift_shop.db`).
///
/// Launch it side by side with the basalt build (`lib/main.dart`) to compare
/// the two ORMs live:
/// `flutter run -t lib/main_drift.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the drift database (seed on first run) and wire the service locator
  // with its repositories.
  await configureDependencies(DriftBackend());

  runApp(const ShopApp());
}
