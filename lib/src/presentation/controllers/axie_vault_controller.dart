// ===============================================================================
// [MODULE_NAME]: axie_vault_controller.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Controllers
// [INTENT]: AsyncNotifier controller managing local sovereign storage of imported Axie cards with reactive updates.
// [DEPENDENCIES]: package:flutter_riverpod/flutter_riverpod.dart, package:shared_preferences/shared_preferences.dart, ../../data/repositories/axie_vault_repository.dart, ../../domain/entities/axie_card_entity.dart
// [ARCHITECTURE]: Riverpod AsyncNotifier
// ===============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/axie_vault_repository.dart';
import '../../domain/entities/axie_card_entity.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main.dart or overridden in ProviderScope');
});

final axieVaultRepositoryProvider = Provider<IAxieVaultRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AxieVaultRepository(prefs: prefs);
});

final axieVaultProvider = AsyncNotifierProvider<AxieVaultController, List<AxieCardEntity>>(() {
  return AxieVaultController();
});

/// Canonical alias for axieVaultProvider matching AC-02 and Blueprint 3.1
final savedAxiesVaultProvider = axieVaultProvider;

class AxieVaultController extends AsyncNotifier<List<AxieCardEntity>> {
  IAxieVaultRepository get _repository => ref.read(axieVaultRepositoryProvider);

  @override
  Future<List<AxieCardEntity>> build() async {
    return await _repository.getSavedAxies();
  }

  Future<void> toggleSaveAxie(AxieCardEntity axie) async {
    final currentList = state.valueOrNull ?? [];
    final isAlreadySaved = currentList.any((a) => a.id == axie.id);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (isAlreadySaved) {
        await _repository.removeAxie(axie.id);
      } else {
        await _repository.saveAxie(axie);
      }
      return await _repository.getSavedAxies();
    });
  }

  bool isSavedSync(String axieId) {
    final list = state.valueOrNull;
    if (list == null) return false;
    return list.any((a) => a.id == axieId);
  }
}
