// ===============================================================================
// [MODULE_NAME]: navigation_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Testing
// [INTENT]: Unit tests for application navigation state.
// [DEPENDENCIES]: package:flutter_test/flutter_test.dart, package:flutter_riverpod/flutter_riverpod.dart, ../lib/src/presentation/controllers/app_navigation_controller.dart, ../lib/src/presentation/controllers/axie_importer_controller.dart
// [ARCHITECTURE]: Unit Tests
// ===============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunacian_card_wars/src/presentation/controllers/app_navigation_controller.dart';
import 'package:lunacian_card_wars/src/presentation/controllers/axie_importer_controller.dart';

void main() {
  group('AppNavigationController', () {
    test('initial state is mainMenu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appNavigationProvider);
      expect(state, AppScreenState.mainMenu);
    });

    test('navigateTo changes state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appNavigationProvider.notifier).navigateTo(AppScreenState.axieVault);
      
      final state = container.read(appNavigationProvider);
      expect(state, AppScreenState.axieVault);
    });

    test('returnToMainMenu resets state to mainMenu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appNavigationProvider.notifier).navigateTo(AppScreenState.settings);
      expect(container.read(appNavigationProvider), AppScreenState.settings);

      container.read(appNavigationProvider.notifier).returnToMainMenu();
      expect(container.read(appNavigationProvider), AppScreenState.mainMenu);
    });

    test('data persistence invariant - axieImporterProvider value remains intact', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialAxieState = container.read(axieImporterProvider);

      container.read(appNavigationProvider.notifier).navigateTo(AppScreenState.axieVault);
      container.read(appNavigationProvider.notifier).returnToMainMenu();
      
      final afterNavAxieState = container.read(axieImporterProvider);
      expect(afterNavAxieState, same(initialAxieState));
    });
  });
}
