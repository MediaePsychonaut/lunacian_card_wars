// ===============================================================================
// [MODULE_NAME]: settings_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: Placeholder for the Settings view.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, ../controllers/app_navigation_controller.dart, widgets/atmospheric_battlefield_backdrop.dart
// [ARCHITECTURE]: ConsumerWidget
// ===============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/app_navigation_controller.dart';
import 'widgets/atmospheric_battlefield_backdrop.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AtmosphericBattlefieldBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, color: Colors.amber),
                    label: const Text('Return to Menu', style: TextStyle(color: Colors.amber)),
                    onPressed: () => ref.read(appNavigationProvider.notifier).returnToMainMenu(),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'SETTINGS COMING SOON',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
