// ===============================================================================
// [MODULE_NAME]: deck_builder_controller.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Controllers
// [INTENT]: Manages the active deck composition (20 to 25 cards), Axie calibration configurations, and universal support cards (Spells and Structures).
// [DEPENDENCIES]: package:flutter_riverpod/flutter_riverpod.dart, ../../domain/entities/axie_card_entity.dart, ../../domain/entities/combat/combat_card.dart, ../../domain/entities/combat/building_card_entity.dart, ../../domain/entities/combat/spell_card_entity.dart, ../../domain/entities/combat/floop_ability_entity.dart, ../../domain/services/axie_card_factory.dart, axie_vault_controller.dart
// [ARCHITECTURE]: Riverpod Notifier Pattern
// ===============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/axie_card_entity.dart';
import '../../domain/entities/combat/combat_card.dart';
import '../../domain/entities/combat/building_card_entity.dart';
import '../../domain/entities/combat/spell_card_entity.dart';
import '../../domain/entities/combat/floop_ability_entity.dart';
import '../../domain/services/axie_card_factory.dart';
import 'axie_vault_controller.dart';

final starterAxiesListProvider = Provider<List<AxieCardEntity>>((ref) {
  return [
    AxieCardFactory.bubaStarter(),
    AxieCardFactory.olekStarter(),
    AxieCardFactory.puffyStarter(),
  ];
});

final fullAvailableAxiesProvider = Provider<List<AxieCardEntity>>((ref) {
  final starters = ref.watch(starterAxiesListProvider);
  final vaultAsync = ref.watch(savedAxiesVaultProvider);
  final vaultAxies = vaultAsync.valueOrNull ?? [];

  final map = <String, AxieCardEntity>{};
  for (final a in starters) {
    map[a.id] = a;
  }
  for (final a in vaultAxies) {
    map[a.id] = a;
  }
  return map.values.toList();
});

final deckBuilderProvider = NotifierProvider<DeckBuilderController, List<CombatCard>>(() {
  return DeckBuilderController();
});

class DeckBuilderController extends Notifier<List<CombatCard>> {
  String? lastErrorMessage;

  @override
  List<CombatCard> build() {
    return [];
  }

  bool isCardInDeck(String cardId) {
    return state.any((c) {
      if (c.id == cardId) return true;
      final rootId = c.id.contains('_deck_')
          ? c.id.substring(0, c.id.indexOf('_deck_'))
          : c.id;
      return rootId == cardId;
    });
  }

  int getCardCountInDeck(String cardId) {
    return state.where((c) {
      if (c.id == cardId) return true;
      final rootId = c.id.contains('_deck_')
          ? c.id.substring(0, c.id.indexOf('_deck_'))
          : c.id;
      return rootId == cardId;
    }).length;
  }

  bool addAxieToDeck(
    AxieCardEntity axie, {
    required int manaCost,
    required FloopSource floopSource,
  }) {
    if (state.length >= 25) {
      lastErrorMessage = 'Deck is full (maximum 25 cards).';
      return false;
    }

    final rootId = axie.id.contains('_deck_')
        ? axie.id.substring(0, axie.id.indexOf('_deck_'))
        : axie.id;

    // Floop resolution for selected source
    FloopAbilityEntity? floop = axie.floop;
    if (floopSource == FloopSource.tail && axie.tailPartName.isNotEmpty) {
      floop = floop?.copyWith(
            name: '${axie.tailPartName} Whip',
            description: 'Deals direct damage or defensive counter.',
          ) ??
          FloopAbilityEntity(
            id: 'floop_${rootId}_tail',
            name: '${axie.tailPartName} Whip',
            manaCost: 1,
            description: 'Deals 4 damage to opposing lane.',
            targetRequirement: FloopTargetType.laneEnemyUnit,
            effectType: FloopEffectType.directDamage,
            effectValue: 4,
          );
    }

    final configuredAxie = axie.copyWith(
      id: '${rootId}_deck_${state.length + 1}',
      selectedFloop: floopSource,
      floop: floop,
    ).recalculateForManaCost(manaCost);

    // Rule: Maximum 2 copies of identical Axie with identical Floop
    final floopKey = '${configuredAxie.selectedFloop.name}_${configuredAxie.floop?.id ?? "none"}';
    final existingCopies = state.where((c) {
      if (c is! AxieCardEntity) return false;
      final cRootId = c.id.contains('_deck_')
          ? c.id.substring(0, c.id.indexOf('_deck_'))
          : c.id;
      final cFloopKey = '${c.selectedFloop.name}_${c.floop?.id ?? "none"}';
      return cRootId == rootId && cFloopKey == floopKey;
    }).length;

    if (existingCopies >= 2) {
      lastErrorMessage = 'Maximum 2 copies with identical Floop allowed in deck.';
      return false;
    }

    lastErrorMessage = null;
    state = [...state, configuredAxie];
    return true;
  }

  bool addBuildingToDeck(BuildingCardEntity building) {
    if (state.length >= 25) {
      lastErrorMessage = 'Deck is full (maximum 25 cards).';
      return false;
    }

    final rootId = building.id.contains('_deck_')
        ? building.id.substring(0, building.id.indexOf('_deck_'))
        : building.id;

    final existingCopies = state.where((c) {
      if (c is! BuildingCardEntity) return false;
      final cRootId = c.id.contains('_deck_')
          ? c.id.substring(0, c.id.indexOf('_deck_'))
          : c.id;
      return cRootId == rootId;
    }).length;

    if (existingCopies >= 2) {
      lastErrorMessage = 'Maximum 2 copies of "${building.name}" allowed in deck.';
      return false;
    }

    final configuredBuilding = building.copyWith(
      id: '${rootId}_deck_${state.length + 1}',
    );

    lastErrorMessage = null;
    state = [...state, configuredBuilding];
    return true;
  }

  bool addSpellToDeck(SpellCardEntity spell) {
    if (state.length >= 25) {
      lastErrorMessage = 'Deck is full (maximum 25 cards).';
      return false;
    }

    final rootId = spell.id.contains('_deck_')
        ? spell.id.substring(0, spell.id.indexOf('_deck_'))
        : spell.id;

    final existingCopies = state.where((c) {
      if (c is! SpellCardEntity) return false;
      final cRootId = c.id.contains('_deck_')
          ? c.id.substring(0, c.id.indexOf('_deck_'))
          : c.id;
      return cRootId == rootId;
    }).length;

    if (existingCopies >= 2) {
      lastErrorMessage = 'Maximum 2 copies of "${spell.name}" allowed in deck.';
      return false;
    }

    final configuredSpell = spell.copyWith(
      id: '${rootId}_deck_${state.length + 1}',
    );

    lastErrorMessage = null;
    state = [...state, configuredSpell];
    return true;
  }

  void removeCardFromDeck(String cardInstanceId) {
    state = state.where((c) => c.id != cardInstanceId).toList();
  }

  void clearDeck() {
    state = [];
    lastErrorMessage = null;
  }

  void loadCanonicalPreset() {
    state = AxieCardFactory.createCanonicalDeck('p1');
    lastErrorMessage = null;
  }
}
