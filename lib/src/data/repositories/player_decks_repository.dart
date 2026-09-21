// ===============================================================================
// [MODULE_NAME]: player_decks_repository.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Data / Repositories
// [INTENT]: Manages local persistence for player decks via SharedPreferences with capacity for at least 10 custom decks and the 6 pre-loaded pure decks.
// [DEPENDENCIES]: package:shared_preferences/shared_preferences.dart, package:flutter_riverpod/flutter_riverpod.dart, dart:convert, ../../domain/entities/deck_entity.dart, ../../domain/services/pure_deck_catalog.dart, ../../presentation/controllers/axie_vault_controller.dart
// [ARCHITECTURE]: Clean Architecture Repository Pattern
// ===============================================================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/services/pure_deck_catalog.dart';
import '../../presentation/controllers/axie_vault_controller.dart';

abstract class IPlayerDecksRepository {
  List<DeckEntity> getAvailableDecks();
  Future<bool> saveCustomDeck(DeckEntity deck);
  Future<bool> deleteCustomDeck(String deckId);
}

class PlayerDecksRepository implements IPlayerDecksRepository {
  final SharedPreferences? _prefs;
  static const String _storageKey = 'lcw_saved_player_decks_v1';

  PlayerDecksRepository(this._prefs);

  @override
  List<DeckEntity> getAvailableDecks() {
    final results = <DeckEntity>[];
    // 1. The 6 Canonical Pure Decks always included first
    results.addAll(PureDeckCatalog.allPureDecks);

    // 2. Load saved custom decks from SharedPreferences
    if (_prefs != null) {
      final rawJson = _prefs.getString(_storageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawJson) as List<dynamic>;
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              results.add(DeckEntity.fromJson(item));
            }
          }
        } catch (_) {}
      }
    }

    return results;
  }

  @override
  Future<bool> saveCustomDeck(DeckEntity deck) async {
    if (_prefs == null) return false;
    final currentCustomDecks = _loadCustomDecksOnly();

    // Enforce at least 10 custom deck slots capacity (or replace existing by id)
    final existingIndex = currentCustomDecks.indexWhere((d) => d.id == deck.id);
    if (existingIndex >= 0) {
      currentCustomDecks[existingIndex] = deck.copyWith(isPreset: false);
    } else {
      if (currentCustomDecks.length >= 20) {
        // Drop oldest if reaching high capacity limit
        currentCustomDecks.removeAt(0);
      }
      currentCustomDecks.add(deck.copyWith(isPreset: false));
    }

    final encoded = jsonEncode(currentCustomDecks.map((d) => d.toJson()).toList());
    return await _prefs.setString(_storageKey, encoded);
  }

  @override
  Future<bool> deleteCustomDeck(String deckId) async {
    if (_prefs == null) return false;
    final currentCustomDecks = _loadCustomDecksOnly();
    currentCustomDecks.removeWhere((d) => d.id == deckId);
    final encoded = jsonEncode(currentCustomDecks.map((d) => d.toJson()).toList());
    return await _prefs.setString(_storageKey, encoded);
  }

  List<DeckEntity> _loadCustomDecksOnly() {
    if (_prefs == null) return [];
    final rawJson = _prefs.getString(_storageKey);
    if (rawJson == null || rawJson.isEmpty) return [];

    try {
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => DeckEntity.fromJson(item))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final playerDecksRepositoryProvider = Provider<IPlayerDecksRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlayerDecksRepository(prefs);
});

final availableDecksProvider = Provider<List<DeckEntity>>((ref) {
  final repo = ref.watch(playerDecksRepositoryProvider);
  return repo.getAvailableDecks();
});
