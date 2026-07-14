import 'package:basalt_example/core/backend/app_backend.dart';
import 'package:basalt_example/core/di/injector.dart';
import 'package:basalt_example/presentation/cart/cart_cubit.dart';
import 'package:basalt_example/presentation/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root widget. The cart cubit is provided here so it is shared across every tab
/// and any route pushed on top (e.g. product detail).
class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Which backend is actually running is decided by the launched entrypoint;
    // its label rides along in a corner ribbon so the two parallel instances
    // (basalt / drift) are instantly distinguishable on screen.
    final backend = getIt<AppBackend>().label;
    return BlocProvider(
      create: (_) => CartCubit(getIt()),
      // Above MaterialApp so pushed routes (e.g. product detail) can read the cart.
      child: MaterialApp(
        title: 'Basalt Shop · $backend',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: Banner(
          message: backend,
          location: BannerLocation.topEnd,
          child: const HomeShell(),
        ),
      ),
    );
  }
}
