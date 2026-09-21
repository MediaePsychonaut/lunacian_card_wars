// ===============================================================================
// [MODULE_NAME]: player_decks_repository.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Data / Repositories
// [INTENT]: Manages local persistence for player decks via SharedPreferences with in-memory fallback, supporting at least 10 custom decks and the 6 pre-loaded pure decks.
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
  static final List<DeckEntity> _inMemoryCustomDecks = [];

  PlayerDecksRepository(this._prefs);

  @override
  List<DeckEntity> getAvailableDecks() {
    final results = <DeckEntity>[];
    // 1. The 6 Canonical Pure Decks always included first (25 cards each)
    results.addAll(PureDeckCatalog.allPureDecks);

    // 2. Load saved custom decks from SharedPreferences or in-memory fallback
    final customDecks = _loadCustomDecksOnly();
    for (final d in customDecks) {
      // Don't duplicate if already present
      if (!results.any((r) => r.id == d.id)) {
        results.add(d);
      }
    }

    return results;
  }

  @override
  Future<bool> saveCustomDeck(DeckEntity deck) async {
    final customDeck = deck.copyWith(isPreset: false);

    // 1. Update in-memory storage
    final memIdx = _inMemoryCustomDecks.indexWhere((d) => d.id == customDeck.id);
    if (memIdx >= 0) {
      _inMemoryCustomDecks[memIdx] = customDeck;
    } else {
      if (_inMemoryCustomDecks.length >= 25) {
        _inMemoryCustomDecks.removeAt(0);
      }
      _inMemoryCustomDecks.add(customDeck);
    }

    // 2. Persist to SharedPreferences if available
    if (_prefs != null) {
      final currentCustomDecks = _loadCustomDecksFromPrefs();
      final existingIndex = currentCustomDecks.indexWhere((d) => d.id == customDeck.id);
      if (existingIndex >= 0) {
        currentCustomDecks[existingIndex] = customDeck;
      } else {
        if (currentCustomDecks.length >= 25) {
          currentCustomDecks.removeAt(0);
        }
        currentCustomDecks.add(customDeck);
      }

      final encoded = jsonEncode(currentCustomDecks.map((d) => d.toJson()).toList());
      await _prefs.setString(_storageKey, encoded);
    }

    return true;
  }

  @override
  Future<bool> deleteCustomDeck(String deckId) async {
    _inMemoryCustomDecks.removeWhere((d) => d.id == deckId);

    if (_prefs != null) {
      final currentCustomDecks = _loadCustomDecksFromPrefs();
      currentCustomDecks.removeWhere((d) => d.id == deckId);
      final encoded = jsonEncode(currentCustomDecks.map((d) => d.toJson()).toList());
      await _prefs.setString(_storageKey, encoded);
    }

    return true;
  }

  List<DeckEntity> _loadCustomDecksOnly() {
    if (_prefs != null) {
      final fromPrefs = _loadCustomDecksFromPrefs();
      if (fromPrefs.isNotEmpty) {
        // Synchronize in-memory cache
        for (final d in fromPrefs) {
          if (!_inMemoryCustomDecks.any((m) => m.id == d.id)) {
            _inMemoryCustomDecks.add(d);
          }
        }
        return fromPrefs;
      }
    }
    return List.from(_inMemoryCustomDecks);
  }

  List<DeckEntity> _loadCustomDecksFromPrefs() {
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
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return PlayerDecksRepository(prefs);
  } catch (_) {
    return PlayerDecksRepository(null);
  }
});

final availableDecksProvider = Provider<List<DeckEntity>>((ref) {
  final repo = ref.watch(playerDecksRepositoryProvider);
  return repo.getAvailableDecks();
});
