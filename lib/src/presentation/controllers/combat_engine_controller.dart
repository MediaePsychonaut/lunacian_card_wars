// ===============================================================================
// [MODULE_NAME]: combat_engine_controller.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Controllers
// [INTENT]: Manages combat engine state, selective mulligan tracking, canonical 20-card decks, tactical spells, and floop activations.
// [DEPENDENCIES]: package:flutter_riverpod/flutter_riverpod.dart, ../../domain/services/combat_engine.dart, ../../domain/services/axie_card_factory.dart, ../../domain/entities/combat/game_state.dart, ../../domain/entities/combat/game_action.dart, ../../domain/entities/combat/combat_enums.dart, ../../domain/entities/combat/combat_card.dart, ../../domain/entities/combat/building_card_entity.dart, ../../domain/entities/combat/spell_card_entity.dart, ../../domain/entities/axie_card_entity.dart
// [ARCHITECTURE]: Riverpod Notifier Controller
// ===============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/combat_engine.dart';
import '../../domain/entities/combat/game_state.dart';
import '../../domain/entities/combat/game_action.dart';
import '../../domain/entities/combat/combat_enums.dart';
import '../../domain/entities/combat/combat_card.dart';
import '../../domain/entities/combat/building_card_entity.dart';
import '../../domain/entities/combat/spell_card_entity.dart';
import '../../domain/entities/axie_card_entity.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/services/pure_deck_catalog.dart';

final combatEngineProvider = NotifierProvider<CombatEngineController, GameState>(CombatEngineController.new);

class CombatEngineController extends Notifier<GameState> {
  final CombatEngine _engine = CombatEngine();

  // Independent Symmetrical Console UI Selection State for Dual Cockpit
  String? selectedP1CardId;
  int selectedP1Lane = 0;
  String? selectedP2CardId;
  int selectedP2Lane = 0;

  // Selective Mulligan Tracking State
  final Set<String> p1MulliganSelection = {};
  final Set<String> p2MulliganSelection = {};

  // Legacy / Fallback Active Target
  PlayerId selectedPlayer = PlayerId.p1;
  String? get selectedCardId => selectedPlayer == PlayerId.p1 ? selectedP1CardId : selectedP2CardId;
  int get selectedLane => selectedPlayer == PlayerId.p1 ? selectedP1Lane : selectedP2Lane;

  // Active Selected Decks for P1 and P2
  DeckEntity? activeP1Deck;
  DeckEntity? activeP2Deck;

  @override
  GameState build() {
    selectedP1CardId = null;
    selectedP1Lane = 0;
    selectedP2CardId = null;
    selectedP2Lane = 0;
    selectedPlayer = PlayerId.p1;
    p1MulliganSelection.clear();
    p2MulliganSelection.clear();

    final p1 = activeP1Deck ?? PureDeckCatalog.beastPureDeck();
    final p2 = activeP2Deck ?? PureDeckCatalog.plantPureDeck();
    activeP1Deck = p1;
    activeP2Deck = p2;

    return _engine.initializeGame(
      p1Deck: p1.cards,
      p2Deck: p2.cards,
      p1Landscapes: p1.landscapes,
      p2Landscapes: p2.landscapes,
    );
  }

  void startBattleWithDecks({
    required DeckEntity p1Deck,
    required DeckEntity p2Deck,
  }) {
    activeP1Deck = p1Deck;
    activeP2Deck = p2Deck;
    selectedP1CardId = null;
    selectedP1Lane = 0;
    selectedP2CardId = null;
    selectedP2Lane = 0;
    selectedPlayer = PlayerId.p1;
    p1MulliganSelection.clear();
    p2MulliganSelection.clear();

    state = _engine.initializeGame(
      p1Deck: p1Deck.cards,
      p2Deck: p2Deck.cards,
      p1Landscapes: p1Deck.landscapes,
      p2Landscapes: p2Deck.landscapes,
    );
  }

  void toggleMulliganCard(PlayerId player, String cardId) {
    final set = player == PlayerId.p1 ? p1MulliganSelection : p2MulliganSelection;
    if (set.contains(cardId)) {
      set.remove(cardId);
    } else {
      set.add(cardId);
    }
    state = state.copyWith();
  }

  void confirmMulligan(PlayerId player) {
    final selectedIds = (player == PlayerId.p1 ? p1MulliganSelection : p2MulliganSelection).toList();
    mulliganCards(player, selectedIds);
    if (player == PlayerId.p1) {
      p1MulliganSelection.clear();
    } else {
      p2MulliganSelection.clear();
    }
  }

  void keepEntireHand(PlayerId player) {
    mulliganCards(player, const []);
    if (player == PlayerId.p1) {
      p1MulliganSelection.clear();
    } else {
      p2MulliganSelection.clear();
    }
  }

  void selectP1Card(String? id) {
    selectedP1CardId = id;
    state = state.copyWith();
  }

  void selectP1Lane(int lane) {
    selectedP1Lane = lane;
    state = state.copyWith();
  }

  void selectP2Card(String? id) {
    selectedP2CardId = id;
    state = state.copyWith();
  }

  void selectP2Lane(int lane) {
    selectedP2Lane = lane;
    state = state.copyWith();
  }

  void selectCardFor(PlayerId player, String? id) {
    if (player == PlayerId.p1) {
      selectedP1CardId = id;
    } else {
      selectedP2CardId = id;
    }
    state = state.copyWith();
  }

  void selectLaneFor(PlayerId player, int lane) {
    if (player == PlayerId.p1) {
      selectedP1Lane = lane;
    } else {
      selectedP2Lane = lane;
    }
    state = state.copyWith();
  }

  String? selectedCardFor(PlayerId player) =>
      player == PlayerId.p1 ? selectedP1CardId : selectedP2CardId;

  int selectedLaneFor(PlayerId player) =>
      player == PlayerId.p1 ? selectedP1Lane : selectedP2Lane;

  void selectPlayer(PlayerId player) {
    selectedPlayer = player;
    state = state.copyWith();
  }

  void selectCard(String? id) {
    if (selectedPlayer == PlayerId.p1) {
      selectedP1CardId = id;
    } else {
      selectedP2CardId = id;
    }
    state = state.copyWith();
  }

  void selectLane(int lane) {
    if (selectedPlayer == PlayerId.p1) {
      selectedP1Lane = lane;
    } else {
      selectedP2Lane = lane;
    }
    state = state.copyWith();
  }

  void startBattle({
    List<CombatCard>? p1Deck,
    List<CombatCard>? p2Deck,
    List<BoardClassAffinity>? p1Landscapes,
    List<BoardClassAffinity>? p2Landscapes,
  }) {
    selectedP1CardId = null;
    selectedP1Lane = 0;
    selectedP2CardId = null;
    selectedP2Lane = 0;
    selectedPlayer = PlayerId.p1;
    p1MulliganSelection.clear();
    final p1 = p1Deck != null ? null : (activeP1Deck ?? PureDeckCatalog.beastPureDeck());
    final p2 = p2Deck != null ? null : (activeP2Deck ?? PureDeckCatalog.plantPureDeck());
    state = _engine.initializeGame(
      p1Deck: p1Deck ?? p1!.cards,
      p2Deck: p2Deck ?? p2!.cards,
      p1Landscapes: p1Landscapes ?? p1!.landscapes,
      p2Landscapes: p2Landscapes ?? p2!.landscapes,
    );
  }

  void dispatchAction(GameAction action) {
    state = _engine.reduce(state, action);
  }

  void passTurn(PlayerId player) {
    dispatchAction(PassPhaseAction(player));
  }

  void passPhase() {
    dispatchAction(PassPhaseAction(state.activePlayer));
  }
  
  void advancePhase() {
    state = _engine.advancePhase(state);
  }

  void placeTile(PlayerId player, int laneIndex, BoardClassAffinity affinity) {
    dispatchAction(PlaceTileAction(player, laneIndex, affinity));
  }

  void mulliganCards(PlayerId player, List<String> cardInstanceIds) {
    dispatchAction(MulliganAction(player, cardInstanceIds));
  }

  ({bool canDeploy, String reason}) canDeploySelected([PlayerId? player]) {
    final targetPlayer = player ?? selectedPlayer;
    final cardId = targetPlayer == PlayerId.p1 ? selectedP1CardId : selectedP2CardId;
    final lane = targetPlayer == PlayerId.p1 ? selectedP1Lane : selectedP2Lane;

    if (state.winner != null) {
      return (canDeploy: false, reason: 'Battle has concluded.');
    }

    if (state.phase == TurnPhase.turnZeroTilePlacement) {
      return (canDeploy: false, reason: 'Tile placement in progress. Place landscapes first.');
    }
    if (state.phase == TurnPhase.turnZeroMulligan) {
      return (canDeploy: false, reason: 'Mulligan in progress. Complete mulligan first.');
    }
    if (state.phase == TurnPhase.clashPhase || state.phase == TurnPhase.roundEnd || state.phase == TurnPhase.roundStart) {
      return (canDeploy: false, reason: 'Cannot summon units/buildings/spells during ${state.phase.name}.');
    }

    if (state.phase == TurnPhase.p1Turn && targetPlayer != PlayerId.p1) {
      return (canDeploy: false, reason: 'Active phase is Player 1 Turn.');
    }
    if (state.phase == TurnPhase.p2Turn && targetPlayer != PlayerId.p2) {
      return (canDeploy: false, reason: 'Active phase is Player 2 Turn.');
    }
    if (state.phase == TurnPhase.p1ReactiveWindow && targetPlayer != PlayerId.p1) {
      return (canDeploy: false, reason: 'Active phase is P1 Reactive Window.');
    }

    if (cardId == null) {
      return (canDeploy: false, reason: 'No card selected from hand.');
    }

    final playerState = state.players[targetPlayer];
    if (playerState == null) {
      return (canDeploy: false, reason: 'Player state not found.');
    }

    final card = playerState.hand.where((c) => c.id == cardId).firstOrNull;
    if (card == null) {
      return (canDeploy: false, reason: 'Selected card is not in ${targetPlayer.name.toUpperCase()} hand.');
    }

    if (playerState.currentMana < card.manaCost) {
      return (canDeploy: false, reason: 'Insufficient mana (${playerState.currentMana}/${card.manaCost}).');
    }

    if (lane < 0 || lane >= state.lanes.length) {
      return (canDeploy: false, reason: 'Invalid lane index: $lane.');
    }

    final slot = state.lanes[lane].getSlot(targetPlayer);

    if (card is AxieCardEntity) {
      if (slot.occupant != null) {
        return (canDeploy: false, reason: 'Lane $lane is already occupied by ${slot.occupant!.name}.');
      }

      if (slot.tileAffinity == null) {
        return (canDeploy: false, reason: 'No landscape tile placed in Lane $lane for ${targetPlayer.name.toUpperCase()}.');
      }

      if (card.affinity != slot.tileAffinity && card.affinity != BoardClassAffinity.neutral) {
        return (
          canDeploy: false,
          reason: 'Mismatched affinity: Card is ${card.affinity.name.toUpperCase()} but Lane $lane is ${slot.tileAffinity!.name.toUpperCase()}.',
        );
      }
    } else if (card is BuildingCardEntity) {
      if (state.phase == TurnPhase.p1ReactiveWindow) {
        return (canDeploy: false, reason: 'Cannot deploy buildings during reactive window.');
      }
      if (slot.building != null) {
        return (canDeploy: false, reason: 'Lane $lane already has building ${slot.building!.name}.');
      }
    } else if (card is SpellCardEntity) {
      if (state.phase == TurnPhase.p1ReactiveWindow) {
        return (canDeploy: false, reason: 'Cannot cast spells during reactive window.');
      }
      if (card.targetType == SpellTargetType.alliedUnit) {
        if (state.lanes[lane].getSlot(targetPlayer).occupant == null) {
          return (canDeploy: false, reason: 'Target lane $lane has no allied unit.');
        }
      } else if (card.targetType == SpellTargetType.enemyUnit) {
        if (state.lanes[lane].getOpposingSlot(targetPlayer).occupant == null) {
          return (canDeploy: false, reason: 'Target lane $lane has no enemy unit.');
        }
      }
      return (canDeploy: true, reason: 'Ready to cast ${card.name}.');
    }

    return (canDeploy: true, reason: 'Ready to deploy.');
  }

  void deploySelectedCard([PlayerId? player]) {
    final targetPlayer = player ?? selectedPlayer;
    final validation = canDeploySelected(targetPlayer);
    if (!validation.canDeploy) return;

    final cardId = targetPlayer == PlayerId.p1 ? selectedP1CardId : selectedP2CardId;
    final lane = targetPlayer == PlayerId.p1 ? selectedP1Lane : selectedP2Lane;
    final playerState = state.players[targetPlayer]!;
    final card = playerState.hand.firstWhere((c) => c.id == cardId);

    if (card is AxieCardEntity) {
      if (state.phase == TurnPhase.p1ReactiveWindow && targetPlayer == PlayerId.p1) {
        dispatchAction(ReactPlayAction(targetPlayer, card, lane));
      } else {
        dispatchAction(PlayUnitAction(targetPlayer, card, lane));
      }
    } else if (card is BuildingCardEntity) {
      dispatchAction(PlayBuildingAction(targetPlayer, lane, card.id));
    } else if (card is SpellCardEntity) {
      dispatchAction(PlaySpellAction(
        player: targetPlayer,
        cardInstanceId: card.id,
        targetLaneIndex: lane,
      ));
    }

    if (targetPlayer == PlayerId.p1) {
      selectedP1CardId = null;
    } else {
      selectedP2CardId = null;
    }
  }

  void castSpell(PlayerId player, String cardId, int laneIndex) {
    dispatchAction(PlaySpellAction(
      player: player,
      cardInstanceId: cardId,
      targetLaneIndex: laneIndex,
    ));
  }

  void deployUnit(PlayerId player, AxieCardEntity card, int laneIndex) {
    dispatchAction(PlayUnitAction(player, card, laneIndex));
  }

  void deployBuilding(PlayerId player, String cardId, int laneIndex) {
    dispatchAction(PlayBuildingAction(player, laneIndex, cardId));
  }

  void deployTestUnit(PlayerId player, int laneIndex) {
    final playerState = state.players[player];
    if (playerState == null) return;
    final affordableUnits = playerState.unitHand.where((c) => _engine.canPlayUnit(state, player, c, laneIndex)).toList();
    if (affordableUnits.isNotEmpty) {
      final cardToPlay = affordableUnits.first;
      if (state.phase == TurnPhase.p1ReactiveWindow && player == PlayerId.p1) {
        dispatchAction(ReactPlayAction(player, cardToPlay, laneIndex));
      } else {
        dispatchAction(PlayUnitAction(player, cardToPlay, laneIndex));
      }
      return;
    }
    final affordableBuildings = playerState.buildingHand.where((c) => _engine.canPlayBuilding(state, player, c, laneIndex)).toList();
    if (affordableBuildings.isNotEmpty) {
      dispatchAction(PlayBuildingAction(player, laneIndex, affordableBuildings.first.id));
    }
  }

  void triggerFloop(PlayerId player, int laneIndex) {
    dispatchAction(ActivateFloopAction(player, laneIndex));
  }

  void resetBattle() {
    selectedP1CardId = null;
    selectedP1Lane = 0;
    selectedP2CardId = null;
    selectedP2Lane = 0;
    selectedPlayer = PlayerId.p1;
    p1MulliganSelection.clear();
    p2MulliganSelection.clear();
    final p1 = activeP1Deck ?? PureDeckCatalog.beastPureDeck();
    final p2 = activeP2Deck ?? PureDeckCatalog.plantPureDeck();
    state = _engine.initializeGame(
      p1Deck: p1.cards,
      p2Deck: p2.cards,
      p1Landscapes: p1.landscapes,
      p2Landscapes: p2.landscapes,
    );
  }

  List<GameAction> getLegalActions(PlayerId player) {
    return _engine.getLegalActions(state, player);
  }
}
