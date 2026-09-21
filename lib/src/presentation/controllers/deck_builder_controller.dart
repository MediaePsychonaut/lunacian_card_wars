// ===============================================================================
// [MODULE_NAME]: deck_builder_controller.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Controllers
// [INTENT]: Manages active deck composition (20 to 25 cards), 4 landscape tiles selection restricted to deck Axie classes, max 2 floops per type enforcement, authentic Floop resolution from CSV, and deck persistence.
// [DEPENDENCIES]: package:flutter_riverpod/flutter_riverpod.dart, ../../domain/entities/axie_card_entity.dart, ../../domain/entities/combat/combat_card.dart, ../../domain/entities/combat/building_card_entity.dart, ../../domain/entities/combat/spell_card_entity.dart, ../../domain/entities/combat/floop_ability_entity.dart, ../../domain/entities/combat/combat_enums.dart, ../../domain/entities/deck_entity.dart, ../../domain/services/axie_card_factory.dart, ../../domain/services/pure_deck_catalog.dart, ../../data/repositories/floop_catalog_repository.dart, ../../data/repositories/player_decks_repository.dart, axie_vault_controller.dart
// [ARCHITECTURE]: Riverpod Notifier Pattern
// ===============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/floop_catalog_repository.dart';
import '../../data/repositories/player_decks_repository.dart';
import '../../domain/entities/axie_card_entity.dart';
import '../../domain/entities/combat/building_card_entity.dart';
import '../../domain/entities/combat/combat_card.dart';
import '../../domain/entities/combat/combat_enums.dart';
import '../../domain/entities/combat/floop_ability_entity.dart';
import '../../domain/entities/combat/spell_card_entity.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/services/pure_deck_catalog.dart';
import 'axie_vault_controller.dart';

final starterAxiesListProvider = Provider<List<AxieCardEntity>>((ref) {
  final floopRepo = ref.watch(floopCatalogRepositoryProvider);

  final bubaFloop = floopRepo.getFloopForPart(partName: 'Nutcracker', partType: 'mouth', axieClass: AxieElementalClass.beast);
  final olekFloop = floopRepo.getFloopForPart(partName: 'Serious', partType: 'mouth', axieClass: AxieElementalClass.plant);
  final puffyFloop = floopRepo.getFloopForPart(partName: 'Lam', partType: 'mouth', axieClass: AxieElementalClass.aquatic);

  return [
    _bubaStarter(bubaFloop),
    _olekStarter(olekFloop),
    _puffyStarter(puffyFloop),
  ];
});

AxieCardEntity _bubaStarter(FloopAbilityEntity floop) {
  return AxieCardEntity(
    id: 'axie_buba',
    name: 'Buba',
    axieClass: AxieElementalClass.beast,
    level: 25,
    manaCost: 3,
    baseAtk: 16,
    baseDef: 11,
    initialPips: 1,
    maxPips: 3,
    mouthPartName: 'Nutcracker',
    tailPartName: 'Cottontail',
    selectedFloop: FloopSource.mouth,
    spriteUrl: 'https://assets.axieinfinity.com/axies/buba/axie/axie-full-transparent.png',
    proxySpriteUrl: 'https://wsrv.nl/?url=buba',
    rawGenes: const {'class': 'beast', 'name': 'Buba'},
    floop: floop,
  );
}

AxieCardEntity _olekStarter(FloopAbilityEntity floop) {
  return AxieCardEntity(
    id: 'axie_olek',
    name: 'Olek',
    axieClass: AxieElementalClass.plant,
    level: 25,
    manaCost: 3,
    baseAtk: 9,
    baseDef: 18,
    initialPips: 0,
    maxPips: 3,
    mouthPartName: 'Serious',
    tailPartName: 'Carrot',
    selectedFloop: FloopSource.mouth,
    spriteUrl: 'https://assets.axieinfinity.com/axies/olek/axie/axie-full-transparent.png',
    proxySpriteUrl: 'https://wsrv.nl/?url=olek',
    rawGenes: const {'class': 'plant', 'name': 'Olek'},
    floop: floop,
  );
}

AxieCardEntity _puffyStarter(FloopAbilityEntity floop) {
  return AxieCardEntity(
    id: 'axie_puffy',
    name: 'Puffy',
    axieClass: AxieElementalClass.aquatic,
    level: 25,
    manaCost: 3,
    baseAtk: 14,
    baseDef: 13,
    initialPips: 0,
    maxPips: 3,
    mouthPartName: 'Lam',
    tailPartName: 'Nimo',
    selectedFloop: FloopSource.mouth,
    spriteUrl: 'https://assets.axieinfinity.com/axies/puffy/axie/axie-full-transparent.png',
    proxySpriteUrl: 'https://wsrv.nl/?url=puffy',
    rawGenes: const {'class': 'aquatic', 'name': 'Puffy'},
    floop: floop,
  );
}

final fullAvailableAxiesProvider = Provider<List<AxieCardEntity>>((ref) {
  final starters = ref.watch(starterAxiesListProvider);
  final vaultAsync = ref.watch(savedAxiesVaultProvider);
  final vaultAxies = vaultAsync.valueOrNull ?? [];
  final floopRepo = ref.watch(floopCatalogRepositoryProvider);

  final map = <String, AxieCardEntity>{};
  for (final a in starters) {
    map[a.id] = a;
  }
  for (final a in vaultAxies) {
    // Ensure vault Axie has its real Floop loaded if missing
    if (a.floop == null) {
      final partName = a.selectedFloop == FloopSource.mouth ? a.mouthPartName : a.tailPartName;
      final partType = a.selectedFloop == FloopSource.mouth ? 'mouth' : 'tail';
      final resolvedFloop = floopRepo.getFloopForPart(
        partName: partName,
        partType: partType,
        axieClass: a.axieClass,
      );
      map[a.id] = a.copyWith(floop: resolvedFloop);
    } else {
      map[a.id] = a;
    }
  }
  return map.values.toList();
});

/// Manages the 4 Landscape Tiles configured for the active deck
final deckBuilderLandscapesProvider =
    NotifierProvider<DeckLandscapesController, List<BoardClassAffinity>>(() {
  return DeckLandscapesController();
});

class DeckLandscapesController extends Notifier<List<BoardClassAffinity>> {
  @override
  List<BoardClassAffinity> build() {
    return [
      BoardClassAffinity.beast,
      BoardClassAffinity.beast,
      BoardClassAffinity.beast,
      BoardClassAffinity.beast,
    ];
  }

  void setLandscapes(List<BoardClassAffinity> landscapes) {
    state = List.from(landscapes);
  }

  bool setLandscapeAt(int index, BoardClassAffinity affinity, Set<BoardClassAffinity> allowedClasses) {
    if (index < 0 || index >= 4) return false;
    if (allowedClasses.isNotEmpty && !allowedClasses.contains(affinity)) {
      return false;
    }
    final next = List<BoardClassAffinity>.from(state);
    while (next.length <= index) {
      next.add(affinity);
    }
    next[index] = affinity;
    state = next;
    return true;
  }

  void autoFill(Set<BoardClassAffinity> allowedClasses) {
    if (allowedClasses.isEmpty) return;
    final classesList = allowedClasses.toList();
    final newTiles = <BoardClassAffinity>[];
    for (int i = 0; i < 4; i++) {
      newTiles.add(classesList[i % classesList.length]);
    }
    state = newTiles;
  }
}

final deckBuilderProvider = NotifierProvider<DeckBuilderController, List<CombatCard>>(() {
  return DeckBuilderController();
});

class DeckBuilderController extends Notifier<List<CombatCard>> {
  String? lastErrorMessage;
  String currentDeckName = 'Custom Deck';
  String? currentDeckId;

  FloopCatalogRepository get _floopRepo => FloopCatalogRepository();

  @override
  List<CombatCard> build() {
    return [];
  }

  /// Axie Elemental Classes currently present in the deck
  Set<BoardClassAffinity> get axieClassesInDeck {
    final affinities = <BoardClassAffinity>{};
    for (final c in state) {
      if (c is AxieCardEntity) {
        affinities.add(c.classAffinity);
      }
    }
    return affinities;
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

    // 1. Resolve authentic Floop ability from CSV matrix
    final partName = floopSource == FloopSource.mouth ? axie.mouthPartName : axie.tailPartName;
    final partType = floopSource == FloopSource.mouth ? 'mouth' : 'tail';
    final floop = _floopRepo.getFloopForPart(
      partName: partName,
      partType: partType,
      axieClass: axie.axieClass,
    );

    // 2. Rule: Maximum 2 copies of identical Floop ability in the same deck
    final floopKey = floop.name.toLowerCase();
    final existingFloops = state.where((c) {
      if (c is! AxieCardEntity || c.floop == null) return false;
      return c.floop!.name.toLowerCase() == floopKey;
    }).length;

    if (existingFloops >= 2) {
      lastErrorMessage = 'Maximum 2 copies of Floop "${floop.name}" allowed in deck.';
      return false;
    }

    // 3. Rule: Maximum 2 copies of identical Axie creature
    final existingAxieCopies = state.where((c) {
      if (c is! AxieCardEntity) return false;
      final cRootId = c.id.contains('_deck_')
          ? c.id.substring(0, c.id.indexOf('_deck_'))
          : c.id;
      return cRootId == rootId;
    }).length;

    if (existingAxieCopies >= 2) {
      lastErrorMessage = 'Maximum 2 copies of "${axie.name}" allowed in deck.';
      return false;
    }

    final configuredAxie = axie.copyWith(
      id: '${rootId}_deck_${state.length + 1}',
      selectedFloop: floopSource,
      floop: floop,
    ).recalculateForManaCost(manaCost);

    lastErrorMessage = null;
    state = [...state, configuredAxie];

    // Automatically align landscapes if needed
    _checkAndSyncLandscapes();

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
    _checkAndSyncLandscapes();
  }

  void clearDeck() {
    state = [];
    currentDeckId = null;
    currentDeckName = 'Custom Deck';
    lastErrorMessage = null;
  }

  void loadCanonicalPreset() {
    loadDeck(PureDeckCatalog.beastPureDeck());
  }

  void loadCanonicalPureDeck(AxieElementalClass axieClass) {
    loadDeck(PureDeckCatalog.getDeckByClass(axieClass));
  }

  void loadDeck(DeckEntity deck) {
    state = List.from(deck.cards);
    currentDeckName = deck.name;
    currentDeckId = deck.id;
    lastErrorMessage = null;
    ref.read(deckBuilderLandscapesProvider.notifier).setLandscapes(deck.landscapes);
  }

  Future<bool> saveActiveDeck(String name) async {
    final allowed = axieClassesInDeck;
    var landscapes = List<BoardClassAffinity>.from(ref.read(deckBuilderLandscapesProvider));

    if (state.length < 20) {
      lastErrorMessage = 'Deck must have at least 20 cards (currently ${state.length}).';
      return false;
    }
    if (state.length > 25) {
      lastErrorMessage = 'Deck exceeds maximum of 25 cards (currently ${state.length}).';
      return false;
    }

    // Auto-align landscapes to deck Axies if invalid or incomplete
    if (allowed.isNotEmpty) {
      final hasInvalid = landscapes.length != 4 || landscapes.any((l) => !allowed.contains(l));
      if (hasInvalid) {
        final allowedList = allowed.toList();
        landscapes = List.generate(4, (i) => allowedList[i % allowedList.length]);
        ref.read(deckBuilderLandscapesProvider.notifier).setLandscapes(landscapes);
      }
    } else if (landscapes.length != 4) {
      landscapes = const [
        BoardClassAffinity.beast,
        BoardClassAffinity.beast,
        BoardClassAffinity.beast,
        BoardClassAffinity.beast,
      ];
      ref.read(deckBuilderLandscapesProvider.notifier).setLandscapes(landscapes);
    }

    // A custom deck must not overwrite a preset ID
    final isPreset = currentDeckId != null && currentDeckId!.startsWith('deck_pure_');
    final deckId = (currentDeckId != null && !isPreset)
        ? currentDeckId!
        : 'custom_deck_${DateTime.now().millisecondsSinceEpoch}';

    final deck = DeckEntity(
      id: deckId,
      name: name.trim().isNotEmpty ? name.trim() : currentDeckName,
      cards: List.from(state),
      landscapes: List.from(landscapes),
      isPreset: false,
    );

    final repo = ref.read(playerDecksRepositoryProvider);
    final success = await repo.saveCustomDeck(deck);
    if (success) {
      currentDeckId = deckId;
      currentDeckName = deck.name;
      lastErrorMessage = null;
      ref.invalidate(availableDecksProvider);
    } else {
      lastErrorMessage = 'Failed to persist deck to storage.';
    }
    return success;
  }

  void _checkAndSyncLandscapes() {
    final allowed = axieClassesInDeck;
    if (allowed.isEmpty) return;

    final currentLandscapes = ref.read(deckBuilderLandscapesProvider);
    final hasInvalid = currentLandscapes.any((l) => !allowed.contains(l));
    if (hasInvalid) {
      ref.read(deckBuilderLandscapesProvider.notifier).autoFill(allowed);
    }
  }
}
