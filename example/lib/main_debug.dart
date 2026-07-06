import 'package:basalt/devtools.dart';
import 'package:basalt_example/app.dart';
import 'package:basalt_example/core/database/app_database.dart';
import 'package:basalt_example/core/di/injector.dart';
import 'package:flutter/material.dart';

/// Debug entrypoint — registers the open connection with the Basalt DevTools
/// inspector so its tables can be browsed/edited from the DevTools "basalt" tab.
/// Launch with `flutter run -t lib/main_debug.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the database, apply migrations from bundled assets, seed on first run.
  final db = await AppDatabase.open();

  BasaltDevTools.register(
    db,
    name: 'main',
  );

  // Wire the service locator with the open connection + repositories.
  configureDependencies(db);

  runApp(const ShopApp());
}
