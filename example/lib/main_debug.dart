import 'package:basalt/devtools.dart';
import 'package:basalt_example/app.dart';
import 'package:basalt_example/core/backend/basalt_backend.dart';
import 'package:basalt_example/core/di/injector.dart';
import 'package:flutter/material.dart';

/// Debug entrypoint (basalt) — registers the open connection with the Basalt
/// DevTools inspector so its tables can be browsed/edited from the DevTools
/// "basalt" tab. Launch with `flutter run -t lib/main_debug.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the basalt database + wire the service locator with its repositories.
  final backend = BasaltBackend();
  await configureDependencies(backend);

  BasaltDevTools.register(
    backend.connection,
    name: 'main',
  );

  runApp(const ShopApp());
}
