// ===============================================================================
// [MODULE_NAME]: main_menu_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: Renders the main menu hub with an oscillating logo and tactile navigation buttons.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, dart:math, widgets/atmospheric_battlefield_backdrop.dart, widgets/tactile_menu_button.dart, ../controllers/app_navigation_controller.dart
// [ARCHITECTURE]: ConsumerWidget
// ===============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'widgets/atmospheric_battlefield_backdrop.dart';
import 'widgets/tactile_menu_button.dart';
import '../controllers/app_navigation_controller.dart';

class MainMenuView extends ConsumerWidget {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AtmosphericBattlefieldBackdrop(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _LogoAnimation(),
            const SizedBox(height: 12),
            const Text(
              'VIBEATHON EDITION',
              style: TextStyle(
                color: Color(0xFFFFB812),
                fontSize: 16,
                letterSpacing: 4.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            TactileMenuButton(
              label: 'PLAY BATTLE',
              icon: Icons.sports_esports,
              glowColor: const Color(0xFFFFB812),
              onPressed: () => ref.read(appNavigationProvider.notifier).navigateTo(AppScreenState.play),
            ),
            TactileMenuButton(
              label: 'DECKBUILDER',
              icon: Icons.dashboard_customize,
              glowColor: const Color(0xFF00E5FF),
              onPressed: () => ref.read(appNavigationProvider.notifier).navigateTo(AppScreenState.deckbuilder),
            ),
            TactileMenuButton(
              label: 'AXIE VAULT',
              icon: Icons.inventory_2,
              glowColor: const Color(0xFF6CC000),
              onPressed: () => ref.read(appNavigationProvider.notifier).navigateTo(AppScreenState.axieVault),
            ),
            TactileMenuButton(
              label: 'SETTINGS',
              icon: Icons.settings,
              glowColor: const Color(0xFFA045E6),
              onPressed: () => ref.read(appNavigationProvider.notifier).navigateTo(AppScreenState.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoAnimation extends StatefulWidget {
  const _LogoAnimation();

  @override
  State<_LogoAnimation> createState() => _LogoAnimationState();
}

class _LogoAnimationState extends State<_LogoAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 6 * math.sin(_controller.value * 2 * math.pi)),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/logo.png',
        height: 140,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.shield,
          size: 140,
          color: Colors.amber,
        ),
      ),
    );
  }
}
