// ===============================================================================
// [MODULE_NAME]: combat_engine_controller.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Controllers
// [INTENT]: Manages the combat engine state and acts as Riverpod controller for the arena view.
// [DEPENDENCIES]: package:flutter_riverpod/flutter_riverpod.dart, ../../domain/services/combat_engine.dart, ../../domain/entities/combat/game_state.dart, ../../domain/entities/combat/game_action.dart, ../../domain/entities/combat/combat_enums.dart, ../../domain/entities/axie_card_entity.dart
// [ARCHITECTURE]: Riverpod Notifier Controller
// ===============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/combat_engine.dart';
import '../../domain/entities/combat/game_state.dart';
import '../../domain/entities/combat/game_action.dart';
import '../../domain/entities/combat/combat_enums.dart';
import '../../domain/entities/axie_card_entity.dart';

final combatEngineProvider = NotifierProvider<CombatEngineController, GameState>(CombatEngineController.new);

class CombatEngineController extends Notifier<GameState> {
  final CombatEngine _engine = CombatEngine();

  // Symmetrical Console UI Selection State
  PlayerId selectedPlayer = PlayerId.p1;
  String? selectedCardId;
  int selectedLane = 0;

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
    selectedPlayer = PlayerId.p1;
    selectedCardId = null;
    selectedLane = 0;
    return _engine.initializeGame(
      p1Deck: _generateTestDeck(15, 'p1'),
      p2Deck: _generateTestDeck(15, 'p2'),
      p1Landscapes: defaultP1Landscapes,
      p2Landscapes: defaultP2Landscapes,
    );
  }

  List<AxieCardEntity> _generateTestDeck(int count, String prefix) {
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

  void selectPlayer(PlayerId player) {
    selectedPlayer = player;
    selectedCardId = null;
    state = state.copyWith();
  }

  void selectCard(String? id) {
    selectedCardId = id;
    state = state.copyWith();
  }

  void selectLane(int lane) {
    selectedLane = lane;
    state = state.copyWith();
  }

  void startBattle({
    List<AxieCardEntity>? p1Deck,
    List<AxieCardEntity>? p2Deck,
    List<BoardClassAffinity>? p1Landscapes,
    List<BoardClassAffinity>? p2Landscapes,
  }) {
    selectedPlayer = PlayerId.p1;
    selectedCardId = null;
    selectedLane = 0;
    state = _engine.initializeGame(
      p1Deck: p1Deck ?? _generateTestDeck(15, 'p1'),
      p2Deck: p2Deck ?? _generateTestDeck(15, 'p2'),
      p1Landscapes: p1Landscapes ?? defaultP1Landscapes,
      p2Landscapes: p2Landscapes ?? defaultP2Landscapes,
    );
  }

  void dispatchAction(GameAction action) {
    state = _engine.reduce(state, action);
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

  ({bool canDeploy, String reason}) canDeploySelected() {
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
      return (canDeploy: false, reason: 'Cannot summon units during ${state.phase.name}.');
    }

    if (state.phase == TurnPhase.p1Turn && selectedPlayer != PlayerId.p1) {
      return (canDeploy: false, reason: 'Active phase is Player 1 Turn.');
    }
    if (state.phase == TurnPhase.p2Turn && selectedPlayer != PlayerId.p2) {
      return (canDeploy: false, reason: 'Active phase is Player 2 Turn.');
    }
    if (state.phase == TurnPhase.p1ReactiveWindow && selectedPlayer != PlayerId.p1) {
      return (canDeploy: false, reason: 'Active phase is P1 Reactive Window.');
    }

    if (selectedCardId == null) {
      return (canDeploy: false, reason: 'No card selected from hand.');
    }

    final playerState = state.players[selectedPlayer];
    if (playerState == null) {
      return (canDeploy: false, reason: 'Player state not found.');
    }

    final card = playerState.hand.where((c) => c.id == selectedCardId).firstOrNull;
    if (card == null) {
      return (canDeploy: false, reason: 'Selected card is not in ${selectedPlayer.name.toUpperCase()} hand.');
    }

    if (playerState.currentMana < card.manaCost) {
      return (canDeploy: false, reason: 'Insufficient mana (${playerState.currentMana}/${card.manaCost}).');
    }

    if (selectedLane < 0 || selectedLane >= state.lanes.length) {
      return (canDeploy: false, reason: 'Invalid lane index: $selectedLane.');
    }

    final slot = state.lanes[selectedLane].getSlot(selectedPlayer);
    if (slot.occupant != null) {
      return (canDeploy: false, reason: 'Lane $selectedLane is already occupied by ${slot.occupant!.name}.');
    }

    if (slot.tileAffinity == null) {
      return (canDeploy: false, reason: 'No landscape tile placed in Lane $selectedLane for ${selectedPlayer.name.toUpperCase()}.');
    }

    if (card.affinity != slot.tileAffinity && card.affinity != BoardClassAffinity.neutral) {
      return (
        canDeploy: false,
        reason: 'Mismatched affinity: Card is ${card.affinity.name.toUpperCase()} but Lane $selectedLane is ${slot.tileAffinity!.name.toUpperCase()}.',
      );
    }

    return (canDeploy: true, reason: 'Ready to deploy.');
  }

  void deploySelectedCard() {
    final validation = canDeploySelected();
    if (!validation.canDeploy) return;

    final playerState = state.players[selectedPlayer]!;
    final card = playerState.hand.firstWhere((c) => c.id == selectedCardId);

    if (state.phase == TurnPhase.p1ReactiveWindow && selectedPlayer == PlayerId.p1) {
      dispatchAction(ReactPlayAction(selectedPlayer, card, selectedLane));
    } else {
      dispatchAction(PlayUnitAction(selectedPlayer, card, selectedLane));
    }
  }

  void deployTestUnit(PlayerId player, int laneIndex) {
    final playerState = state.players[player];
    if (playerState == null) return;
    final affordable = playerState.hand.where((c) => _engine.canPlayUnit(state, player, c, laneIndex)).toList();
    if (affordable.isEmpty) return;
    final cardToPlay = affordable.first;

    if (state.phase == TurnPhase.p1ReactiveWindow && player == PlayerId.p1) {
      dispatchAction(ReactPlayAction(player, cardToPlay, laneIndex));
    } else {
      dispatchAction(PlayUnitAction(player, cardToPlay, laneIndex));
    }
  }

  void triggerFloop(PlayerId player, int laneIndex) {
    dispatchAction(ActivateFloopAction(player, laneIndex));
  }

  void resetBattle() {
    selectedPlayer = PlayerId.p1;
    selectedCardId = null;
    selectedLane = 0;
    state = _engine.initializeGame(
      p1Deck: _generateTestDeck(15, 'p1'),
      p2Deck: _generateTestDeck(15, 'p2'),
      p1Landscapes: defaultP1Landscapes,
      p2Landscapes: defaultP2Landscapes,
    );
  }

  List<GameAction> getLegalActions(PlayerId player) {
    return _engine.getLegalActions(state, player);
  }
}
