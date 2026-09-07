// ===============================================================================
// [MODULE_NAME]: main.dart
// [SYSTEM]: Lunacian Card Wars
// [DOMAIN]: Application Entry Point & Baseline Canvas
// [INTENT]: Bootstraps the Flutter Web CanvasKit application. Renders the official
//           Lunacian Card Wars logo centered on a dark game canvas (#1A1A1A).
//           Serves as the verified runtime baseline before gameplay logic is layered.
// [DEPENDENCIES]: flutter/material.dart
// [ARCHITECTURE]: Stateless presentation-only entry point. No domain or data imports.
// ===============================================================================

import 'package:flutter/material.dart';

void main() {
  runApp(const LunacianCardWarsApp());
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
      home: const GameCanvas(),
    );
  }
}

class GameCanvas extends StatelessWidget {
  const GameCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480.0),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
