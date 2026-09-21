// ===============================================================================
// [MODULE_NAME]: main.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Application Entry Point & Baseline Canvas
// [INTENT]: Bootstraps the Flutter Web CanvasKit application. Provides the global ProviderScope with SharedPreferences overrides and routes to the RootView.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, package:shared_preferences/shared_preferences.dart, src/presentation/controllers/axie_vault_controller.dart, src/presentation/views/root_view.dart
// [ARCHITECTURE]: Stateless presentation-only entry point. Riverpod ProviderScope wrapper.
// ===============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/presentation/controllers/axie_vault_controller.dart';
import 'src/presentation/views/root_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LunacianCardWarsApp(),
    ),
  );
}

class LunacianCardWarsApp extends StatelessWidget {
  const LunacianCardWarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lunacian Card Wars',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
      home: const RootView(),
    );
  }
}
