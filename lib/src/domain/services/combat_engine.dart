// ===============================================================================
// [MODULE_NAME]: combat_engine.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Services
// [INTENT]: Pure deterministic engine for combat rules, interleaved tile drafting, priority inversion, tactical building auras, and lethal short-circuit clash
// [DEPENDENCIES]: ../entities/combat/combat_enums.dart, ../entities/combat/game_state.dart, ../entities/combat/player_state_entity.dart, ../entities/combat/board_lane_entity.dart, ../entities/combat/game_action.dart, ../entities/combat/board_unit_entity.dart, ../entities/combat/board_building_entity.dart, ../entities/combat/building_card_entity.dart, ../entities/combat/combat_card.dart, ../entities/axie_card_entity.dart
// [ARCHITECTURE]: Pure Domain Service
// ===============================================================================

import 'dart:math';
import '../entities/combat/combat_enums.dart';
import '../entities/combat/game_state.dart';
import '../entities/combat/player_state_entity.dart';
import '../entities/combat/board_lane_entity.dart';
import '../entities/combat/game_action.dart';
import '../entities/combat/board_unit_entity.dart';
import '../entities/combat/board_building_entity.dart';
import '../entities/combat/building_card_entity.dart';
import '../entities/combat/combat_card.dart';
import '../entities/axie_card_entity.dart';

class CombatEngine {
  GameState initializeGame({
    required List<CombatCard> p1Deck,
    required List<CombatCard> p2Deck,
    List<BoardClassAffinity>? p1Landscapes,
    List<BoardClassAffinity>? p2Landscapes,
    PlayerId initialActivePlayer = PlayerId.p1,
  }) {
    final p1L = p1Landscapes ??
        const [
          BoardClassAffinity.beast,
          BoardClassAffinity.aquatic,
          BoardClassAffinity.plant,
          BoardClassAffinity.bug,
        ];
    final p2L = p2Landscapes ??
        const [
          BoardClassAffinity.beast,
          BoardClassAffinity.aquatic,
          BoardClassAffinity.plant,
          BoardClassAffinity.bug,
        ];

    final p1State = PlayerStateEntity(
      id: PlayerId.p1,
      heroHp: 25,
      maxHp: 25,
      currentMana: 0,
      maxMana: 0,
      hand: const [],
      deck: List<CombatCard>.from(p1Deck),
      graveyard: const [],
      canReact: false,
      hasCompletedMulligan: false,
      landscapeDeck: p1L,
    );

    final p2State = PlayerStateEntity(
      id: PlayerId.p2,
      heroHp: 25,
      maxHp: 25,
      currentMana: 0,
      maxMana: 0,
      hand: const [],
      deck: List<CombatCard>.from(p2Deck),
      graveyard: const [],
      canReact: false,
      hasCompletedMulligan: false,
      landscapeDeck: p2L,
    );

    final initialLanes = List.generate(
      4,
      (index) => BoardLaneEntity(
        laneIndex: index,
        p1Slot: const LaneSlot(),
        p2Slot: const LaneSlot(),
      ),
    );

    return GameState(
      roundNumber: 1,
      phase: TurnPhase.turnZeroTilePlacement,
      activePlayer: initialActivePlayer,
      initiativePlayer: initialActivePlayer,
      firstTilePlacer: initialActivePlayer,
      players: {
        PlayerId.p1: p1State,
        PlayerId.p2: p2State,
      },
      lanes: initialLanes,
      actionHistory: const [],
      logs: const [
        'Game initialized. Turn Zero: Interleaved landscape tile placement active.'
      ],
      p1UnitDestroyedInP2Turn: false,
    );
  }

  int getEffectiveAtk(GameState state, int laneIndex, PlayerId player) {
    if (laneIndex < 0 || laneIndex >= state.lanes.length) return 0;
    final slot = state.lanes[laneIndex].getSlot(player);
    final occupant = slot.occupant;
    if (occupant == null) return 0;
    int atk = occupant.currentAtk;
    if (slot.building != null && slot.building!.effectType == BuildingEffectType.attackAura) {
      atk += slot.building!.effectValue;
    }
    return atk;
  }

  int getEffectiveDef(GameState state, int laneIndex, PlayerId player) {
    if (laneIndex < 0 || laneIndex >= state.lanes.length) return 0;
    final slot = state.lanes[laneIndex].getSlot(player);
    final occupant = slot.occupant;
    if (occupant == null) return 0;
    int def = occupant.currentDef;
    if (slot.building != null && slot.building!.effectType == BuildingEffectType.defenseAura) {
      def += slot.building!.effectValue;
    }
    return def;
  }

  bool canPlayUnit(GameState state, PlayerId player, AxieCardEntity card, int laneIndex) {
    if (laneIndex < 0 || laneIndex >= state.lanes.length) return false;
    final playerState = state.players[player]!;
    if (playerState.currentMana < card.manaCost) return false;
    final slot = state.lanes[laneIndex].getSlot(player);
    if (slot.occupant != null) return false;
    if (slot.tileAffinity == null) return false;
    return card.affinity == slot.tileAffinity || card.affinity == BoardClassAffinity.neutral;
  }

  bool canPlayBuilding(GameState state, PlayerId player, BuildingCardEntity card, int laneIndex) {
    if (laneIndex < 0 || laneIndex >= state.lanes.length) return false;
    final playerState = state.players[player]!;
    if (playerState.currentMana < card.manaCost) return false;
    final slot = state.lanes[laneIndex].getSlot(player);
    return slot.building == null;
  }

  List<GameAction> getLegalActions(GameState state, PlayerId player) {
    if (state.winner != null) return [];

    final List<GameAction> actions = [];
    final playerState = state.players[player]!;

    // 1. Turn Zero Interleaved Tile Placement
    if (state.phase == TurnPhase.turnZeroTilePlacement) {
      if (player == state.activePlayer) {
        final placedAffinities = state.lanes
            .map((l) => l.getSlot(player).tileAffinity)
            .whereType<BoardClassAffinity>()
            .toList();
        final unplacedAffinities = List<BoardClassAffinity>.from(playerState.landscapeDeck);
        for (final placed in placedAffinities) {
          unplacedAffinities.remove(placed);
        }

        for (var i = 0; i < state.lanes.length; i++) {
          if (state.lanes[i].getSlot(player).tileAffinity == null) {
            for (final affinity in unplacedAffinities.toSet()) {
              actions.add(PlaceTileAction(player, i, affinity));
            }
          }
        }
      }
      return actions;
    }

    // 2. Turn Zero Mulligan
    if (state.phase == TurnPhase.turnZeroMulligan) {
      if (player == state.activePlayer && !playerState.hasCompletedMulligan) {
        actions.add(PassPhaseAction(player));
        final handIds = playerState.hand.map((c) => c.id).toList();
        final count = handIds.length;
        final totalSubsets = 1 << count;
        for (int i = 0; i < totalSubsets; i++) {
          final subset = <String>[];
          for (int bit = 0; bit < count; bit++) {
            if ((i & (1 << bit)) != 0) {
              subset.add(handIds[bit]);
            }
          }
          actions.add(MulliganAction(player, subset));
        }
      }
      return actions;
    }

    // 3. Regular Turns
    if (state.phase == TurnPhase.p1Turn && player == PlayerId.p1) {
      actions.add(PassPhaseAction(player));
    } else if (state.phase == TurnPhase.p2Turn && player == PlayerId.p2) {
      actions.add(PassPhaseAction(player));
    } else if (state.phase == TurnPhase.p1ReactiveWindow && player == PlayerId.p1) {
      actions.add(PassPhaseAction(player));
    } else {
      return [];
    }

    if (state.phase == TurnPhase.p1Turn || state.phase == TurnPhase.p2Turn) {
      // Units
      for (final card in playerState.unitHand) {
        for (var i = 0; i < state.lanes.length; i++) {
          if (canPlayUnit(state, player, card, i)) {
            actions.add(PlayUnitAction(player, card, i));
          }
        }
      }
      // Buildings
      for (final card in playerState.buildingHand) {
        for (var i = 0; i < state.lanes.length; i++) {
          if (canPlayBuilding(state, player, card, i)) {
            actions.add(PlayBuildingAction(player, i, card.id));
          }
        }
      }
      // Floop
      for (var i = 0; i < state.lanes.length; i++) {
        final slot = state.lanes[i].getSlot(player);
        if (slot.occupant != null && !slot.occupant!.hasFlooped) {
          actions.add(ActivateFloopAction(player, i));
        }
      }
    } else if (state.phase == TurnPhase.p1ReactiveWindow) {
      for (final card in playerState.unitHand) {
        for (var i = 0; i < state.lanes.length; i++) {
          if (canPlayUnit(state, player, card, i)) {
            actions.add(ReactPlayAction(player, card, i));
          }
        }
      }
    }

    return actions;
  }

  GameState reduce(GameState state, GameAction action) {
    final player = switch (action) {
      PlayUnitAction a => a.player,
      PlayBuildingAction a => a.player,
      ActivateFloopAction a => a.player,
      PassPhaseAction a => a.player,
      ReactPlayAction a => a.player,
      MulliganAction a => a.player,
      PlaceTileAction a => a.player,
    };

    final legalActions = getLegalActions(state, player);

    bool isLegal = false;
    for (final legalAction in legalActions) {
      if (action.runtimeType == legalAction.runtimeType) {
        if (action is PlayUnitAction && legalAction is PlayUnitAction) {
          if (action.card.id == legalAction.card.id && action.laneIndex == legalAction.laneIndex) {
            isLegal = true;
            break;
          }
        } else if (action is PlayBuildingAction && legalAction is PlayBuildingAction) {
          if (action.cardInstanceId == legalAction.cardInstanceId && action.laneIndex == legalAction.laneIndex) {
            isLegal = true;
            break;
          }
        } else if (action is ReactPlayAction && legalAction is ReactPlayAction) {
          if (action.card.id == legalAction.card.id && action.laneIndex == legalAction.laneIndex) {
            isLegal = true;
            break;
          }
        } else if (action is PassPhaseAction && legalAction is PassPhaseAction) {
          isLegal = true;
          break;
        } else if (action is ActivateFloopAction && legalAction is ActivateFloopAction) {
          if (action.laneIndex == legalAction.laneIndex) {
            isLegal = true;
            break;
          }
        } else if (action is MulliganAction && legalAction is MulliganAction) {
          final handIds = state.players[player]!.hand.map((c) => c.id).toSet();
          if (action.cardInstanceIdsToReplace.every((id) => handIds.contains(id))) {
            isLegal = true;
            break;
          }
        } else if (action is PlaceTileAction && legalAction is PlaceTileAction) {
          if (action.laneIndex == legalAction.laneIndex && action.affinity == legalAction.affinity) {
            isLegal = true;
            break;
          }
        }
      }
    }

    if (!isLegal) return state;

    GameState newState = state.copyWith(
      actionHistory: List.from(state.actionHistory)..add(action),
    );

    switch (action) {
      case PlaceTileAction a:
        newState = _placeTile(newState, a.player, a.laneIndex, a.affinity);
        break;
      case MulliganAction a:
        newState = _mulligan(newState, a.player, a.cardInstanceIdsToReplace);
        break;
      case PlayUnitAction a:
        newState = _playUnit(newState, a.player, a.card, a.laneIndex);
        break;
      case ReactPlayAction a:
        newState = _playReactionUnit(newState, a.player, a.card, a.laneIndex);
        break;
      case PlayBuildingAction a:
        newState = _playBuilding(newState, a.player, a.cardInstanceId, a.laneIndex);
        break;
      case ActivateFloopAction a:
        newState = _activateFloop(newState, a.player, a.laneIndex);
        break;
      case PassPhaseAction a:
        if (state.phase == TurnPhase.turnZeroMulligan) {
          newState = _passMulligan(newState, a.player);
        } else {
          newState = advancePhase(newState);
        }
        break;
    }

    return newState;
  }

  GameState _placeTile(GameState state, PlayerId player, int laneIndex, BoardClassAffinity affinity) {
    if (state.activePlayer != player) return state;
    final lane = state.lanes[laneIndex];
    final currentSlot = lane.getSlot(player);
    if (currentSlot.tileAffinity != null) return state;

    final updatedSlot = currentSlot.copyWith(tileAffinity: affinity);
    final updatedLanes = List<BoardLaneEntity>.from(state.lanes);
    updatedLanes[laneIndex] = lane.copyWithSlot(player, updatedSlot);

    final placementLog = '${player.name.toUpperCase()} placed ${affinity.name.toUpperCase()} landscape in Lane $laneIndex.';
    final newLogs = [...state.logs, placementLog];

    var nextState = state.copyWith(lanes: updatedLanes, logs: newLogs);

    final totalPlaced = nextState.lanes.fold<int>(
      0,
      (sum, l) => sum + (l.p1Slot.tileAffinity != null ? 1 : 0) + (l.p2Slot.tileAffinity != null ? 1 : 0),
    );

    if (totalPlaced == 8) {
      final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(nextState.players);
      for (final pid in PlayerId.values) {
        final p = updatedPlayers[pid]!;
        final deck = List<CombatCard>.from(p.deck);
        final hand = deck.take(4).toList();
        final remainingDeck = deck.skip(4).toList();
        updatedPlayers[pid] = p.copyWith(hand: hand, deck: remainingDeck);
      }

      final initialMulliganPlayer = state.firstTilePlacer ?? PlayerId.p1;

      return nextState.copyWith(
        phase: TurnPhase.turnZeroMulligan,
        activePlayer: initialMulliganPlayer,
        players: updatedPlayers,
        logs: [
          ...nextState.logs,
          'All 8 landscapes drafted in interleaved sequence. Hands drawn. Mulligan phase active.',
        ],
      );
    }

    // Interleaved drafting: toggle active player to opponent
    final nextActive = (player == PlayerId.p1) ? PlayerId.p2 : PlayerId.p1;
    return nextState.copyWith(
      activePlayer: nextActive,
      logs: [
        ...nextState.logs,
        'Turn toggled to ${nextActive.name.toUpperCase()} for next tile draft.',
      ],
    );
  }

  GameState _mulligan(GameState state, PlayerId player, List<String> cardInstanceIdsToReplace) {
    final playerState = state.players[player]!;
    final hand = List<CombatCard>.from(playerState.hand);
    final deck = List<CombatCard>.from(playerState.deck);

    final cardsToReplace = hand.where((c) => cardInstanceIdsToReplace.contains(c.id)).toList();
    final remainingHand = hand.where((c) => !cardInstanceIdsToReplace.contains(c.id)).toList();

    final countToDraw = cardsToReplace.length;
    final drawnCards = deck.take(countToDraw).toList();
    final remainingDeck = deck.skip(countToDraw).toList();

    remainingDeck.addAll(cardsToReplace);

    final newHand = [...remainingHand, ...drawnCards];
    final updatedPlayer = playerState.copyWith(
      hand: newHand,
      deck: remainingDeck,
      hasCompletedMulligan: true,
    );

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    updatedPlayers[player] = updatedPlayer;

    final logMsg = '[Turn Zero] ${player.name.toUpperCase()} mulliganed ${cardsToReplace.length} card(s).';
    final intermediateState = state.copyWith(
      players: updatedPlayers,
      logs: [...state.logs, logMsg],
    );

    return _evaluateMulliganProgress(intermediateState);
  }

  GameState _passMulligan(GameState state, PlayerId player) {
    final playerState = state.players[player]!;
    final updatedPlayer = playerState.copyWith(hasCompletedMulligan: true);

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    updatedPlayers[player] = updatedPlayer;

    final logMsg = '[Turn Zero] ${player.name.toUpperCase()} kept opening hand without changes.';
    final intermediateState = state.copyWith(
      players: updatedPlayers,
      logs: [...state.logs, logMsg],
    );

    return _evaluateMulliganProgress(intermediateState);
  }

  GameState _evaluateMulliganProgress(GameState state) {
    final p1 = state.p1;
    final p2 = state.p2;

    if (p1.hasCompletedMulligan && p2.hasCompletedMulligan) {
      return _prepareRoundOne(state);
    } else if (p1.hasCompletedMulligan && !p2.hasCompletedMulligan) {
      return state.copyWith(
        activePlayer: PlayerId.p2,
        logs: [
          ...state.logs,
          '[Turn Zero] P1 completed mulligan. Active player transitioned to P2.'
        ],
      );
    } else if (!p1.hasCompletedMulligan && p2.hasCompletedMulligan) {
      return state.copyWith(
        activePlayer: PlayerId.p1,
        logs: [
          ...state.logs,
          '[Turn Zero] P2 completed mulligan. Active player transitioned to P1.'
        ],
      );
    }

    return state;
  }

  GameState _prepareRoundOne(GameState state) {
    final firstPlacer = state.firstTilePlacer ?? PlayerId.p1;
    final pReact = (firstPlacer == PlayerId.p1) ? PlayerId.p2 : PlayerId.p1;

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    for (final pid in PlayerId.values) {
      final p = updatedPlayers[pid]!;
      updatedPlayers[pid] = p.copyWith(
        currentMana: 1,
        maxMana: 1,
        hasCompletedMulligan: true,
      );
    }

    final openingPhase = (pReact == PlayerId.p1) ? TurnPhase.p1Turn : TurnPhase.p2Turn;

    return state.copyWith(
      roundNumber: 1,
      phase: openingPhase,
      initiativePlayer: pReact,
      activePlayer: pReact,
      players: updatedPlayers,
      logs: [
        ...state.logs,
        '[Round 1] Turn Zero concluded. Priority inverted: ${pReact.name.toUpperCase()} awarded opening initiative with 1 Mana.',
      ],
    );
  }

  GameState _playUnit(GameState state, PlayerId player, AxieCardEntity card, int laneIndex) {
    final playerState = state.players[player]!;
    final updatedHand = playerState.hand.where((c) => c.id != card.id).toList();
    final updatedMana = playerState.currentMana - card.manaCost;

    final deterministicId = '${card.id}_${state.roundNumber}_${state.actionHistory.length}';
    final deterministicUnit = BoardUnitEntity.fromAxieCard(card, instanceId: deterministicId);

    final updatedLanes = List<BoardLaneEntity>.from(state.lanes);
    final lane = updatedLanes[laneIndex];
    final currentSlot = lane.getSlot(player);
    updatedLanes[laneIndex] = lane.copyWithSlot(
      player,
      currentSlot.copyWith(occupant: deterministicUnit),
    );

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    updatedPlayers[player] = playerState.copyWith(hand: updatedHand, currentMana: updatedMana);

    return state.copyWith(
      lanes: updatedLanes,
      players: updatedPlayers,
      logs: [
        ...state.logs,
        '[Play] ${player.name.toUpperCase()} played unit "${card.name}" into Lane $laneIndex.',
      ],
    );
  }

  GameState _playReactionUnit(GameState state, PlayerId player, AxieCardEntity card, int laneIndex) {
    final playerState = state.players[player]!;
    final updatedHand = playerState.hand.where((c) => c.id != card.id).toList();
    final updatedMana = playerState.currentMana - card.manaCost;

    final deterministicId = '${card.id}_react_${state.roundNumber}_${state.actionHistory.length}';
    final deterministicUnit = BoardUnitEntity.fromAxieCard(card, instanceId: deterministicId);

    final updatedLanes = List<BoardLaneEntity>.from(state.lanes);
    final lane = updatedLanes[laneIndex];
    final currentSlot = lane.getSlot(player);
    updatedLanes[laneIndex] = lane.copyWithSlot(
      player,
      currentSlot.copyWith(occupant: deterministicUnit),
    );

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    updatedPlayers[player] = playerState.copyWith(hand: updatedHand, currentMana: updatedMana);

    return state.copyWith(
      lanes: updatedLanes,
      players: updatedPlayers,
      logs: [
        ...state.logs,
        '[Reactive Window] ${player.name.toUpperCase()} played reaction unit "${card.name}" into Lane $laneIndex.',
      ],
    );
  }

  GameState _playBuilding(GameState state, PlayerId player, String cardInstanceId, int laneIndex) {
    final playerState = state.players[player]!;
    final cardIndex = playerState.hand.indexWhere((c) => c.id == cardInstanceId);
    if (cardIndex == -1) return state;
    final card = playerState.hand[cardIndex];
    if (card is! BuildingCardEntity) return state;
    if (playerState.currentMana < card.manaCost) return state;

    final updatedHand = List<CombatCard>.from(playerState.hand)..removeAt(cardIndex);
    final updatedMana = playerState.currentMana - card.manaCost;

    final deterministicId = '${card.id}_${state.roundNumber}_${state.actionHistory.length}';
    final buildingEntity = BoardBuildingEntity.fromCard(card, instanceId: deterministicId);

    final updatedLanes = List<BoardLaneEntity>.from(state.lanes);
    final lane = updatedLanes[laneIndex];
    final currentSlot = lane.getSlot(player);
    updatedLanes[laneIndex] = lane.copyWithSlot(
      player,
      currentSlot.copyWith(building: buildingEntity),
    );

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    updatedPlayers[player] = playerState.copyWith(hand: updatedHand, currentMana: updatedMana);

    return state.copyWith(
      lanes: updatedLanes,
      players: updatedPlayers,
      logs: [
        ...state.logs,
        '[Play] ${player.name.toUpperCase()} placed building "${card.name}" into Lane $laneIndex.',
      ],
    );
  }

  GameState _activateFloop(GameState state, PlayerId player, int laneIndex) {
    final updatedLanes = List<BoardLaneEntity>.from(state.lanes);
    final lane = updatedLanes[laneIndex];
    final currentSlot = lane.getSlot(player);
    final unit = currentSlot.occupant;
    if (unit != null) {
      updatedLanes[laneIndex] = lane.copyWithSlot(
        player,
        currentSlot.copyWith(occupant: unit.copyWith(hasFlooped: true)),
      );
    }
    return state.copyWith(
      lanes: updatedLanes,
      logs: [
        ...state.logs,
        '[Floop] ${player.name.toUpperCase()} activated Floop in Lane $laneIndex.',
      ],
    );
  }

  GameState _autoCompleteTilePlacement(GameState state) {
    var currentState = state;
    while (currentState.phase == TurnPhase.turnZeroTilePlacement) {
      final active = currentState.activePlayer;
      final playerState = currentState.players[active]!;
      final placedAffinities = currentState.lanes
          .map((l) => l.getSlot(active).tileAffinity)
          .whereType<BoardClassAffinity>()
          .toList();
      final unplacedAffinities = List<BoardClassAffinity>.from(playerState.landscapeDeck);
      for (final placed in placedAffinities) {
        unplacedAffinities.remove(placed);
      }

      int targetLane = -1;
      for (var i = 0; i < currentState.lanes.length; i++) {
        if (currentState.lanes[i].getSlot(active).tileAffinity == null) {
          targetLane = i;
          break;
        }
      }

      if (targetLane != -1 && unplacedAffinities.isNotEmpty) {
        currentState = _placeTile(currentState, active, targetLane, unplacedAffinities.first);
      } else {
        break;
      }
    }
    return currentState;
  }

  GameState advancePhase(GameState state) {
    if (state.winner != null) return state;

    switch (state.phase) {
      case TurnPhase.turnZeroTilePlacement:
        return _autoCompleteTilePlacement(state);
      case TurnPhase.turnZeroMulligan:
        return _prepareRoundOne(state);
      case TurnPhase.roundStart:
        return _prepareRoundOne(state);
      case TurnPhase.p1Turn:
        if (state.initiativePlayer == PlayerId.p1) {
          return state.copyWith(
            phase: TurnPhase.p2Turn,
            activePlayer: PlayerId.p2,
            logs: [
              ...state.logs,
              '[FSM] P1 passed turn. Active player: P2.',
            ],
          );
        } else {
          // P1 was second
          return state.copyWith(
            phase: TurnPhase.clashPhase,
            p1UnitDestroyedInP2Turn: false,
            logs: [
              ...state.logs,
              '[FSM] P1 passed second turn -> Advanced to Clash Phase.',
            ],
          );
        }
      case TurnPhase.p2Turn:
        if (state.initiativePlayer == PlayerId.p2) {
          return state.copyWith(
            phase: TurnPhase.p1Turn,
            activePlayer: PlayerId.p1,
            logs: [
              ...state.logs,
              '[FSM] P2 passed turn. Active player: P1.',
            ],
          );
        } else {
          // P2 was second (P1 had initiative)
          final hasPlayableReactionCard = state.p1.hand.any((card) =>
              card is AxieCardEntity &&
              card.manaCost <= state.p1.currentMana &&
              state.lanes.any((lane) => canPlayUnit(state, PlayerId.p1, card, lane.laneIndex)));
          final hasEmptyLaneSlot = state.lanes.any((lane) => lane.p1Slot.occupant == null);
          final canTriggerReactiveWindow = state.p1UnitDestroyedInP2Turn &&
              state.p1.currentMana >= 1 &&
              hasPlayableReactionCard &&
              hasEmptyLaneSlot;

          if (canTriggerReactiveWindow) {
            return state.copyWith(
              phase: TurnPhase.p1ReactiveWindow,
              activePlayer: PlayerId.p1,
              logs: [
                ...state.logs,
                '[FSM] P1 Reactive Window opened (unit destroyed, mana available, reaction card in hand).',
              ],
            );
          } else {
            return state.copyWith(
              phase: TurnPhase.clashPhase,
              p1UnitDestroyedInP2Turn: false,
              logs: [
                ...state.logs,
                '[FSM] Reactive window criteria bypassed -> Advanced to Clash Phase.',
              ],
            );
          }
        }
      case TurnPhase.p1ReactiveWindow:
        return state.copyWith(
          phase: TurnPhase.clashPhase,
          p1UnitDestroyedInP2Turn: false,
          logs: [
            ...state.logs,
            '[FSM] P1 Reactive Window closed -> Advanced to Clash Phase.',
          ],
        );
      case TurnPhase.clashPhase:
        final postClash = resolveClashPhase(state);
        if (postClash.winner != null || postClash.phase == TurnPhase.gameOver) {
          return postClash;
        }
        final nextInitiative = (postClash.initiativePlayer == PlayerId.p1) ? PlayerId.p2 : PlayerId.p1;
        return postClash.copyWith(
          phase: TurnPhase.roundEnd,
          initiativePlayer: nextInitiative,
          logs: [
            ...postClash.logs,
            '[FSM] Clash resolution finished -> Transitioning to Round End. Next initiative: ${nextInitiative.name.toUpperCase()}.',
          ],
        );
      case TurnPhase.roundEnd:
        return _startRound(state);
      case TurnPhase.gameOver:
        return state;
    }
  }

  GameState _startRound(GameState state) {
    final newRoundNumber = state.roundNumber + 1;
    final maxMana = newRoundNumber > 10 ? 10 : newRoundNumber;

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    final roundLogs = <String>[
      '[Round $newRoundNumber] Round start. Mana pool set to $maxMana. Initiative player: ${state.initiativePlayer.name.toUpperCase()}.'
    ];

    var p1Hp = state.p1.heroHp;
    var p2Hp = state.p2.heroHp;

    for (final pid in PlayerId.values) {
      final p = updatedPlayers[pid]!;
      final newHand = List<CombatCard>.from(p.hand);
      final newDeck = List<CombatCard>.from(p.deck);

      if (newDeck.isNotEmpty) {
        final drawn = newDeck.removeAt(0);
        newHand.add(drawn);
        roundLogs.add('[Round $newRoundNumber] ${pid.name.toUpperCase()} drew "${drawn.name}". Deck remaining: ${newDeck.length}.');
      } else {
        if (pid == PlayerId.p1) {
          p1Hp -= 5;
        } else {
          p2Hp -= 5;
        }
        roundLogs.add('[Round $newRoundNumber] ${pid.name.toUpperCase()} deck empty! Suffered -5 HP fatigue penalty (HP: ${pid == PlayerId.p1 ? p1Hp : p2Hp}).');
      }

      updatedPlayers[pid] = p.copyWith(
        currentMana: maxMana,
        maxMana: maxMana,
        hand: newHand,
        deck: newDeck,
        heroHp: pid == PlayerId.p1 ? p1Hp : p2Hp,
      );
    }

    // Lane occupants: reset floop & execute Round Start Repair hook
    final updatedLanes = state.lanes.map((lane) {
      var p1o = lane.p1Slot.occupant;
      var p2o = lane.p2Slot.occupant;
      final p1b = lane.p1Slot.building;
      final p2b = lane.p2Slot.building;

      if (p1o != null) {
        p1o = p1o.copyWith(hasFlooped: false);
        if (p1b != null && p1b.effectType == BuildingEffectType.roundStartRepair) {
          final missingDef = p1o.maxDef - p1o.currentDef;
          if (missingDef > 0) {
            final healAmount = min(missingDef, p1b.effectValue);
            p1o = p1o.copyWith(currentDef: p1o.currentDef + healAmount);
            roundLogs.add('[Repair - Lane ${lane.laneIndex}] P1 building "${p1b.name}" repaired "${p1o.name}" for +$healAmount DEF (${p1o.currentDef}/${p1o.maxDef}).');
          }
        }
      }

      if (p2o != null) {
        p2o = p2o.copyWith(hasFlooped: false);
        if (p2b != null && p2b.effectType == BuildingEffectType.roundStartRepair) {
          final missingDef = p2o.maxDef - p2o.currentDef;
          if (missingDef > 0) {
            final healAmount = min(missingDef, p2b.effectValue);
            p2o = p2o.copyWith(currentDef: p2o.currentDef + healAmount);
            roundLogs.add('[Repair - Lane ${lane.laneIndex}] P2 building "${p2b.name}" repaired "${p2o.name}" for +$healAmount DEF (${p2o.currentDef}/${p2o.maxDef}).');
          }
        }
      }

      return lane.copyWith(
        p1Slot: lane.p1Slot.copyWith(occupant: p1o),
        p2Slot: lane.p2Slot.copyWith(occupant: p2o),
      );
    }).toList();

    PlayerId? winner = state.winner;
    TurnPhase phase = (state.initiativePlayer == PlayerId.p1) ? TurnPhase.p1Turn : TurnPhase.p2Turn;

    if (winner == null) {
      if (p1Hp <= 0 && p2Hp <= 0) {
        winner = null;
        phase = TurnPhase.gameOver;
        roundLogs.add('[Terminal] Both heroes perished to fatigue. Draw.');
      } else if (p1Hp <= 0) {
        winner = PlayerId.p2;
        phase = TurnPhase.gameOver;
        roundLogs.add('[Terminal] P1 perished to fatigue. Winner: P2.');
      } else if (p2Hp <= 0) {
        winner = PlayerId.p1;
        phase = TurnPhase.gameOver;
        roundLogs.add('[Terminal] P2 perished to fatigue. Winner: P1.');
      }
    } else {
      phase = TurnPhase.gameOver;
    }

    return state.copyWith(
      roundNumber: newRoundNumber,
      phase: phase,
      activePlayer: state.initiativePlayer,
      players: updatedPlayers,
      lanes: updatedLanes,
      p1UnitDestroyedInP2Turn: false,
      winner: winner,
      clearWinner: winner == null && phase == TurnPhase.gameOver,
      logs: [...state.logs, ...roundLogs],
    );
  }

  GameState resolveClashPhase(GameState state) {
    var p1Hp = state.p1.heroHp;
    var p2Hp = state.p2.heroHp;

    final p1Grave = List<BoardUnitEntity>.from(state.p1.graveyard);
    final p2Grave = List<BoardUnitEntity>.from(state.p2.graveyard);

    final nextLanes = List<BoardLaneEntity>.from(state.lanes);
    final clashLogs = <String>['[FSM] Resolving Sequential Clash Phase (Lanes 0 to 3).'];

    PlayerId? winner = state.winner;
    TurnPhase currentPhase = state.phase;
    bool shortCircuited = false;

    for (var i = 0; i < state.lanes.length; i++) {
      final lane = nextLanes[i];
      var p1Unit = lane.p1Slot.occupant;
      var p2Unit = lane.p2Slot.occupant;
      var p1Bldg = lane.p1Slot.building;
      var p2Bldg = lane.p2Slot.building;

      // 1. Calculate P1 effective ATK with dynamic aura & crit
      int p1Dmg = 0;
      if (p1Unit != null) {
        int baseAtk = p1Unit.currentAtk;
        if (p1Bldg != null && p1Bldg.effectType == BuildingEffectType.attackAura) {
          baseAtk += p1Bldg.effectValue;
        }
        final isCrit = p1Unit.maxPips > 0 && p1Unit.currentPips >= p1Unit.maxPips;
        if (isCrit) {
          p1Dmg = (baseAtk * 1.25).floor();
          p1Unit = p1Unit.copyWith(currentPips: 0);
          clashLogs.add('[Clash Step 1 - Lane $i] P1 Unit "${p1Unit.name}" CRIT! Dealt $p1Dmg dmg (pips reset to 0/${p1Unit.maxPips}).');
        } else {
          p1Dmg = baseAtk;
          final nextPips = min(p1Unit.maxPips, p1Unit.currentPips + 1);
          p1Unit = p1Unit.copyWith(currentPips: nextPips);
          clashLogs.add('[Clash Step 1 - Lane $i] P1 Unit "${p1Unit.name}" attack: $p1Dmg dmg (pips: $nextPips/${p1Unit.maxPips}).');
        }
      }

      // 2. Calculate P2 effective ATK with dynamic aura & crit
      int p2Dmg = 0;
      if (p2Unit != null) {
        int baseAtk = p2Unit.currentAtk;
        if (p2Bldg != null && p2Bldg.effectType == BuildingEffectType.attackAura) {
          baseAtk += p2Bldg.effectValue;
        }
        final isCrit = p2Unit.maxPips > 0 && p2Unit.currentPips >= p2Unit.maxPips;
        if (isCrit) {
          p2Dmg = (baseAtk * 1.25).floor();
          p2Unit = p2Unit.copyWith(currentPips: 0);
          clashLogs.add('[Clash Step 1 - Lane $i] P2 Unit "${p2Unit.name}" CRIT! Dealt $p2Dmg dmg (pips reset to 0/${p2Unit.maxPips}).');
        } else {
          p2Dmg = baseAtk;
          final nextPips = min(p2Unit.maxPips, p2Unit.currentPips + 1);
          p2Unit = p2Unit.copyWith(currentPips: nextPips);
          clashLogs.add('[Clash Step 1 - Lane $i] P2 Unit "${p2Unit.name}" attack: $p2Dmg dmg (pips: $nextPips/${p2Unit.maxPips}).');
        }
      }

      clashLogs.add('[Clash Step 2 - Lane $i] Simultaneous cross: P1 strikes with $p1Dmg | P2 strikes with $p2Dmg.');

      // 3. P1 strikes P2 side (Trample: Unit DEF + Defense Aura -> Building -> Hero HP)
      if (p1Dmg > 0) {
        if (p2Unit != null) {
          final p2DefAura = (p2Bldg != null && p2Bldg.effectType == BuildingEffectType.defenseAura)
              ? p2Bldg.effectValue
              : 0;
          final effectiveP2Def = p2Unit.currentDef + p2DefAura;

          if (p1Dmg > effectiveP2Def) {
            final overflow = p1Dmg - effectiveP2Def;
            p2Unit = p2Unit.copyWith(currentDef: 0);
            clashLogs.add('[Clash Step 3 - Lane $i] P1 broke P2 DEF (effective DEF: $effectiveP2Def). Overflow: $overflow.');

            if (p2Bldg != null) {
              final actualBldgDmg = max(0, overflow - p2Bldg.armorReduction);
              clashLogs.add('[Clash Step 3 - Lane $i] Overflow $overflow hit P2 building "${p2Bldg.name}" (Armor: ${p2Bldg.armorReduction}, Effective: $actualBldgDmg).');
              if (actualBldgDmg > 0) {
                if (actualBldgDmg > p2Bldg.currentHp) {
                  final bldgOverflow = actualBldgDmg - p2Bldg.currentHp;
                  p2Bldg = p2Bldg.copyWith(currentHp: 0);
                  p2Hp -= bldgOverflow;
                  clashLogs.add('[Clash Step 3 - Lane $i] P2 building destroyed! Residual trample $bldgOverflow dealt to P2 Hero HP (remaining: $p2Hp).');
                } else {
                  p2Bldg = p2Bldg.copyWith(currentHp: p2Bldg.currentHp - actualBldgDmg);
                  clashLogs.add('[Clash Step 3 - Lane $i] P2 building absorbed damage (HP: ${p2Bldg.currentHp}/${p2Bldg.maxHp}).');
                }
              }
            } else {
              p2Hp -= overflow;
              clashLogs.add('[Clash Step 3 - Lane $i] Direct unit trample dealt $overflow damage to P2 Hero HP (remaining: $p2Hp).');
            }
          } else {
            final dmgToUnit = max(0, p1Dmg - p2DefAura);
            p2Unit = p2Unit.copyWith(currentDef: p2Unit.currentDef - dmgToUnit);
            clashLogs.add('[Clash Step 3 - Lane $i] P2 unit absorbed damage (DEF: ${p2Unit.currentDef}/${p2Unit.maxDef}, Aura absorbed: ${min(p1Dmg, p2DefAura)}).');
          }
        } else if (p2Bldg != null) {
          final actualBldgDmg = max(0, p1Dmg - p2Bldg.armorReduction);
          clashLogs.add('[Clash Step 3 - Lane $i] P1 unblocked attack $p1Dmg hit P2 building "${p2Bldg.name}" (Armor: ${p2Bldg.armorReduction}, Effective: $actualBldgDmg).');
          if (actualBldgDmg > 0) {
            if (actualBldgDmg > p2Bldg.currentHp) {
              final bldgOverflow = actualBldgDmg - p2Bldg.currentHp;
              p2Bldg = p2Bldg.copyWith(currentHp: 0);
              p2Hp -= bldgOverflow;
              clashLogs.add('[Clash Step 3 - Lane $i] P2 building destroyed! Residual trample $bldgOverflow dealt to P2 Hero HP (remaining: $p2Hp).');
            } else {
              p2Bldg = p2Bldg.copyWith(currentHp: p2Bldg.currentHp - actualBldgDmg);
              clashLogs.add('[Clash Step 3 - Lane $i] P2 building absorbed direct damage (HP: ${p2Bldg.currentHp}/${p2Bldg.maxHp}).');
            }
          }
        } else {
          p2Hp -= p1Dmg;
          clashLogs.add('[Clash Step 3 - Lane $i] Unblocked direct strike! P1 dealt $p1Dmg directly to P2 Hero HP (remaining: $p2Hp).');
        }
      }

      // 4. P2 strikes P1 side (Trample: Unit DEF + Defense Aura -> Building -> Hero HP)
      if (p2Dmg > 0) {
        if (p1Unit != null) {
          final p1DefAura = (p1Bldg != null && p1Bldg.effectType == BuildingEffectType.defenseAura)
              ? p1Bldg.effectValue
              : 0;
          final effectiveP1Def = p1Unit.currentDef + p1DefAura;

          if (p2Dmg > effectiveP1Def) {
            final overflow = p2Dmg - effectiveP1Def;
            p1Unit = p1Unit.copyWith(currentDef: 0);
            clashLogs.add('[Clash Step 3 - Lane $i] P2 broke P1 DEF (effective DEF: $effectiveP1Def). Overflow: $overflow.');

            if (p1Bldg != null) {
              final actualBldgDmg = max(0, overflow - p1Bldg.armorReduction);
              clashLogs.add('[Clash Step 3 - Lane $i] Overflow $overflow hit P1 building "${p1Bldg.name}" (Armor: ${p1Bldg.armorReduction}, Effective: $actualBldgDmg).');
              if (actualBldgDmg > 0) {
                if (actualBldgDmg > p1Bldg.currentHp) {
                  final bldgOverflow = actualBldgDmg - p1Bldg.currentHp;
                  p1Bldg = p1Bldg.copyWith(currentHp: 0);
                  p1Hp -= bldgOverflow;
                  clashLogs.add('[Clash Step 3 - Lane $i] P1 building destroyed! Residual trample $bldgOverflow dealt to P1 Hero HP (remaining: $p1Hp).');
                } else {
                  p1Bldg = p1Bldg.copyWith(currentHp: p1Bldg.currentHp - actualBldgDmg);
                  clashLogs.add('[Clash Step 3 - Lane $i] P1 building absorbed damage (HP: ${p1Bldg.currentHp}/${p1Bldg.maxHp}).');
                }
              }
            } else {
              p1Hp -= overflow;
              clashLogs.add('[Clash Step 3 - Lane $i] Direct unit trample dealt $overflow damage to P1 Hero HP (remaining: $p1Hp).');
            }
          } else {
            final dmgToUnit = max(0, p2Dmg - p1DefAura);
            p1Unit = p1Unit.copyWith(currentDef: p1Unit.currentDef - dmgToUnit);
            clashLogs.add('[Clash Step 3 - Lane $i] P1 unit absorbed damage (DEF: ${p1Unit.currentDef}/${p1Unit.maxDef}, Aura absorbed: ${min(p2Dmg, p1DefAura)}).');
          }
        } else if (p1Bldg != null) {
          final actualBldgDmg = max(0, p2Dmg - p1Bldg.armorReduction);
          clashLogs.add('[Clash Step 3 - Lane $i] P2 unblocked attack $p2Dmg hit P1 building "${p1Bldg.name}" (Armor: ${p1Bldg.armorReduction}, Effective: $actualBldgDmg).');
          if (actualBldgDmg > 0) {
            if (actualBldgDmg > p1Bldg.currentHp) {
              final bldgOverflow = actualBldgDmg - p1Bldg.currentHp;
              p1Bldg = p1Bldg.copyWith(currentHp: 0);
              p1Hp -= bldgOverflow;
              clashLogs.add('[Clash Step 3 - Lane $i] P1 building destroyed! Residual trample $bldgOverflow dealt to P1 Hero HP (remaining: $p1Hp).');
            } else {
              p1Bldg = p1Bldg.copyWith(currentHp: p1Bldg.currentHp - actualBldgDmg);
              clashLogs.add('[Clash Step 3 - Lane $i] P1 building absorbed direct damage (HP: ${p1Bldg.currentHp}/${p1Bldg.maxHp}).');
            }
          }
        } else {
          p1Hp -= p2Dmg;
          clashLogs.add('[Clash Step 3 - Lane $i] Unblocked direct strike! P2 dealt $p2Dmg directly to P1 Hero HP (remaining: $p1Hp).');
        }
      }

      // 5. Graveyard reaping
      if (p1Unit != null && p1Unit.currentDef <= 0) {
        p1Grave.add(p1Unit);
        clashLogs.add('[Clash Step 4 - Lane $i] P1 Unit "${p1Unit.name}" destroyed -> moved to Graveyard.');
        p1Unit = null;
      }
      if (p2Unit != null && p2Unit.currentDef <= 0) {
        p2Grave.add(p2Unit);
        clashLogs.add('[Clash Step 4 - Lane $i] P2 Unit "${p2Unit.name}" destroyed -> moved to Graveyard.');
        p2Unit = null;
      }
      if (p1Bldg != null && p1Bldg.currentHp <= 0) {
        clashLogs.add('[Clash Step 4 - Lane $i] P1 Building "${p1Bldg.name}" destroyed -> reaped.');
        p1Bldg = null;
      }
      if (p2Bldg != null && p2Bldg.currentHp <= 0) {
        clashLogs.add('[Clash Step 4 - Lane $i] P2 Building "${p2Bldg.name}" destroyed -> reaped.');
        p2Bldg = null;
      }

      nextLanes[i] = lane.copyWith(
        p1Slot: lane.p1Slot.copyWith(
          occupant: p1Unit,
          clearOccupant: p1Unit == null,
          building: p1Bldg,
          clearBuilding: p1Bldg == null,
        ),
        p2Slot: lane.p2Slot.copyWith(
          occupant: p2Unit,
          clearOccupant: p2Unit == null,
          building: p2Bldg,
          clearBuilding: p2Bldg == null,
        ),
      );

      // 6. Immediate Lethal Short-Circuit Check
      if (p1Hp <= 0 && p2Hp <= 0) {
        winner = null;
        currentPhase = TurnPhase.gameOver;
        shortCircuited = true;
        clashLogs.add('[Clash Short-Circuit - Lane $i] Simultaneous double-lethal detected! Game over: Draw.');
        break;
      } else if (p1Hp <= 0 && p2Hp > 0) {
        winner = PlayerId.p2;
        currentPhase = TurnPhase.gameOver;
        shortCircuited = true;
        clashLogs.add('Clash aborted at Lane $i due to lethal damage. Player 2 wins.');
        break;
      } else if (p2Hp <= 0 && p1Hp > 0) {
        winner = PlayerId.p1;
        currentPhase = TurnPhase.gameOver;
        shortCircuited = true;
        clashLogs.add('Clash aborted at Lane $i due to lethal damage. Player 1 wins.');
        break;
      }
    }

    if (!shortCircuited) {
      clashLogs.add('[Clash Step 5] Terminal evaluation: Both heroes survive (P1 HP: $p1Hp, P2 HP: $p2Hp).');
    }

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    updatedPlayers[PlayerId.p1] = state.p1.copyWith(heroHp: p1Hp, graveyard: p1Grave);
    updatedPlayers[PlayerId.p2] = state.p2.copyWith(heroHp: p2Hp, graveyard: p2Grave);

    return state.copyWith(
      lanes: nextLanes,
      players: updatedPlayers,
      phase: currentPhase,
      winner: winner,
      clearWinner: winner == null && currentPhase == TurnPhase.gameOver,
      logs: [...state.logs, ...clashLogs],
    );
  }
}
