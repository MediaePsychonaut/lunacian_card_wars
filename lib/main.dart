// ===============================================================================
// [MODULE_NAME]: main.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Application Entry Point & Baseline Canvas
// [INTENT]: Bootstraps the Flutter Web CanvasKit application. Provides the global ProviderScope and routes to the RootView.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, src/presentation/views/root_view.dart
// [ARCHITECTURE]: Stateless presentation-only entry point. Riverpod ProviderScope wrapper.
// ===============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/presentation/views/root_view.dart';

void main() {
  runApp(const ProviderScope(child: LunacianCardWarsApp()));
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
