// ===============================================================================
// [MODULE_NAME]: root_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: Acts as the top-level shell that switches views based on navigation state.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, ../controllers/app_navigation_controller.dart, main_menu_view.dart, arena_view.dart, deckbuilder_view.dart, axie_vault_view.dart, settings_view.dart
// [ARCHITECTURE]: ConsumerWidget
// ===============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/app_navigation_controller.dart';
import 'main_menu_view.dart';
import 'arena_view.dart';
import 'deckbuilder_view.dart';
import 'axie_vault_view.dart';
import 'settings_view.dart';

class RootView extends ConsumerWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(appNavigationProvider);
    return switch (screen) {
      AppScreenState.mainMenu    => const MainMenuView(),
      AppScreenState.play        => const ArenaView(),
      AppScreenState.deckbuilder => const DeckbuilderView(),
      AppScreenState.axieVault   => const AxieVaultView(),
      AppScreenState.settings    => const SettingsView(),
    };
  }
}
