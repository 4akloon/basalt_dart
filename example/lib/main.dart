import 'package:basalt_example/app.dart';
import 'package:basalt_example/core/database/app_database.dart';
import 'package:basalt_example/core/di/injector.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the database, apply migrations from bundled assets, seed on first run.
  final db = await AppDatabase.open();

  // Wire the service locator with the open connection + repositories.
  configureDependencies(db);

  runApp(const ShopApp());
}
