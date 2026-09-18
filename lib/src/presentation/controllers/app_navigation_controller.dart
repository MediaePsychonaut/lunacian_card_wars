// ===============================================================================
// [MODULE_NAME]: app_navigation_controller.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Controllers
// [INTENT]: Manages the main application navigation state via a simple enum.
// [DEPENDENCIES]: package:flutter_riverpod/flutter_riverpod.dart
// [ARCHITECTURE]: Riverpod NotifierProvider
// ===============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppScreenState { mainMenu, play, deckbuilder, axieVault, settings }

class AppNavigationController extends Notifier<AppScreenState> {
  @override
  AppScreenState build() => AppScreenState.mainMenu;

  void navigateTo(AppScreenState screen) => state = screen;
  void returnToMainMenu() => state = AppScreenState.mainMenu;
}

final appNavigationProvider = NotifierProvider<AppNavigationController, AppScreenState>(
  AppNavigationController.new,
);
