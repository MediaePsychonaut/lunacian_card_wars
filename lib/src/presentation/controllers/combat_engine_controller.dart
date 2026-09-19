// ===============================================================================
// [MODULE_NAME]: combat_engine_controller.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Controllers
// [INTENT]: Manages the combat engine state and acts as Riverpod controller for the arena view with independent P1/P2 selection states and 20-card tactical deck support.
// [DEPENDENCIES]: package:flutter_riverpod/flutter_riverpod.dart, ../../domain/services/combat_engine.dart, ../../domain/entities/combat/game_state.dart, ../../domain/entities/combat/game_action.dart, ../../domain/entities/combat/combat_enums.dart, ../../domain/entities/combat/combat_card.dart, ../../domain/entities/combat/building_card_entity.dart, ../../domain/entities/axie_card_entity.dart
// [ARCHITECTURE]: Riverpod Notifier Controller
// ===============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/combat_engine.dart';
import '../../domain/entities/combat/game_state.dart';
import '../../domain/entities/combat/game_action.dart';
import '../../domain/entities/combat/combat_enums.dart';
import '../../domain/entities/combat/combat_card.dart';
import '../../domain/entities/combat/building_card_entity.dart';
import '../../domain/entities/axie_card_entity.dart';

final combatEngineProvider = NotifierProvider<CombatEngineController, GameState>(CombatEngineController.new);

class CombatEngineController extends Notifier<GameState> {
  final CombatEngine _engine = CombatEngine();

  // Independent Symmetrical Console UI Selection State for Dual Cockpit
  String? selectedP1CardId;
  int selectedP1Lane = 0;
  String? selectedP2CardId;
  int selectedP2Lane = 0;

  // Legacy / Fallback Active Target
  PlayerId selectedPlayer = PlayerId.p1;
  String? get selectedCardId => selectedPlayer == PlayerId.p1 ? selectedP1CardId : selectedP2CardId;
  int get selectedLane => selectedPlayer == PlayerId.p1 ? selectedP1Lane : selectedP2Lane;

  static const defaultP1Landscapes = [
    BoardClassAffinity.beast,
    BoardClassAffinity.aquatic,
    BoardClassAffinity.plant,
    BoardClassAffinity.bug,
  ];

  static const defaultP2Landscapes = [
    BoardClassAffinity.plant,
    BoardClassAffinity.aquatic,
    BoardClassAffinity.beast,
    BoardClassAffinity.bug,
  ];

  @override
  GameState build() {
    selectedP1CardId = null;
    selectedP1Lane = 0;
    selectedP2CardId = null;
    selectedP2Lane = 0;
    selectedPlayer = PlayerId.p1;

    return _engine.initializeGame(
      p1Deck: _generateTestDeck('p1'),
      p2Deck: _generateTestDeck('p2'),
      p1Landscapes: defaultP1Landscapes,
      p2Landscapes: defaultP2Landscapes,
    );
  }

  List<AxieCardEntity> _generateAxieCards(int count, String prefix) {
    final classes = [
      'beast',
      'aquatic',
      'plant',
      'bug',
      'bird',
      'reptile',
    ];
    return List.generate(count, (i) {
      final className = classes[i % classes.length];
      return AxieCardEntity.fromGraphQL({
        'id': '${prefix}_card_$i',
        'name': '${prefix.toUpperCase()} ${className.toUpperCase()} $i',
        'class': className,
        'level': (i % 3) * 10,
        'parts': [
          {'type': 'mouth', 'name': 'Nut Cracker'},
          {'type': 'tail', 'name': 'Nut Throw'},
          {'type': 'horn', 'name': 'Dual Blade'},
          {'type': 'back', 'name': 'Ronin'}
        ],
      });
    });
  }

  List<CombatCard> _generateTestDeck(String prefix) {
    final axies = _generateAxieCards(15, prefix);
    final buildings = [
      BuildingCardEntity.attackTotem(id: '${prefix}_atk_totem_1'),
      BuildingCardEntity.attackTotem(id: '${prefix}_atk_totem_2'),
      BuildingCardEntity.defenseBarricade(id: '${prefix}_def_barricade_1'),
      BuildingCardEntity.defenseBarricade(id: '${prefix}_def_barricade_2'),
      BuildingCardEntity.vitalityShrine(id: '${prefix}_vitality_shrine_1'),
    ];
    return [...axies, ...buildings];
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
    state = _engine.initializeGame(
      p1Deck: p1Deck ?? _generateTestDeck('p1'),
      p2Deck: p2Deck ?? _generateTestDeck('p2'),
      p1Landscapes: p1Landscapes ?? defaultP1Landscapes,
      p2Landscapes: p2Landscapes ?? defaultP2Landscapes,
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
      return (canDeploy: false, reason: 'Cannot summon units/buildings during ${state.phase.name}.');
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
    }

    if (targetPlayer == PlayerId.p1) {
      selectedP1CardId = null;
    } else {
      selectedP2CardId = null;
    }
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
    state = _engine.initializeGame(
      p1Deck: _generateTestDeck('p1'),
      p2Deck: _generateTestDeck('p2'),
      p1Landscapes: defaultP1Landscapes,
      p2Landscapes: defaultP2Landscapes,
    );
  }

  List<GameAction> getLegalActions(PlayerId player) {
    return _engine.getLegalActions(state, player);
  }
}
