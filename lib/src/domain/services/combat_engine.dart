// ===============================================================================
// [MODULE_NAME]: combat_engine.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Services
// [INTENT]: Pure deterministic engine for combat rules, Turn Zero mulligan, and FSM transitions
// [DEPENDENCIES]: ../entities/combat/combat_enums.dart, ../entities/combat/game_state.dart, ../entities/combat/player_state_entity.dart, ../entities/combat/board_lane_entity.dart, ../entities/combat/game_action.dart, ../entities/combat/board_unit_entity.dart, ../entities/combat/board_building_entity.dart, ../entities/axie_card_entity.dart
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
import '../entities/axie_card_entity.dart';

class CombatEngine {
  GameState initializeGame({
    required List<AxieCardEntity> p1Deck,
    required List<AxieCardEntity> p2Deck,
    List<BoardClassAffinity>? p1Landscapes,
    List<BoardClassAffinity>? p2Landscapes,
    int? seed,
  }) {
    final lanes = List.generate(4, (i) {
      return BoardLaneEntity(
        laneIndex: i,
        p1Slot: const LaneSlot(),
        p2Slot: const LaneSlot(),
      );
    });

    final defaultLandscapes = const [
      BoardClassAffinity.beast,
      BoardClassAffinity.aquatic,
      BoardClassAffinity.plant,
      BoardClassAffinity.bug,
    ];

    final p1 = PlayerStateEntity(
      id: PlayerId.p1,
      heroHp: 25,
      maxHp: 25,
      currentMana: 0,
      maxMana: 0,
      hand: const [],
      deck: List<AxieCardEntity>.from(p1Deck),
      graveyard: const [],
      canReact: true,
      hasCompletedMulligan: false,
      landscapeDeck: p1Landscapes ?? defaultLandscapes,
    );

    final p2 = PlayerStateEntity(
      id: PlayerId.p2,
      heroHp: 25,
      maxHp: 25,
      currentMana: 0,
      maxMana: 0,
      hand: const [],
      deck: List<AxieCardEntity>.from(p2Deck),
      graveyard: const [],
      canReact: false,
      hasCompletedMulligan: false,
      landscapeDeck: p2Landscapes ?? defaultLandscapes,
    );

    return GameState(
      roundNumber: 1,
      phase: TurnPhase.turnZeroTilePlacement,
      activePlayer: PlayerId.p1,
      initiativePlayer: PlayerId.p1,
      players: {PlayerId.p1: p1, PlayerId.p2: p2},
      lanes: lanes,
      actionHistory: const [],
      logs: const [
        'Game initialized. Turn Zero: Landscape tile placement active.'
      ],
      p1UnitDestroyedInP2Turn: false,
    );
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

  List<GameAction> getLegalActions(GameState state, PlayerId player) {
    if (state.winner != null) return [];

    final List<GameAction> actions = [];
    final playerState = state.players[player]!;

    // 1. Turn Zero Tile Placement
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
      for (final card in playerState.hand) {
        for (var i = 0; i < state.lanes.length; i++) {
          if (canPlayUnit(state, player, card, i)) {
            actions.add(PlayUnitAction(player, card, i));
          }
        }
      }
      for (var i = 0; i < state.lanes.length; i++) {
        final slot = state.lanes[i].getSlot(player);
        if (slot.occupant != null && !slot.occupant!.hasFlooped) {
          actions.add(ActivateFloopAction(player, i));
        }
      }
    } else if (state.phase == TurnPhase.p1ReactiveWindow) {
      for (final card in playerState.hand) {
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
        } else if (action is PlayBuildingAction && legalAction is PlayBuildingAction) {
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

    if (!isLegal && action is PlayBuildingAction) {
      if ((state.phase == TurnPhase.p1Turn && player == PlayerId.p1) ||
          (state.phase == TurnPhase.p2Turn && player == PlayerId.p2)) {
        if (action.laneIndex >= 0 && action.laneIndex < state.lanes.length) {
          final slot = state.lanes[action.laneIndex].getSlot(player);
          if (slot.building == null) {
            isLegal = true;
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
        newState = _playBuilding(newState, a.player, a.building, a.laneIndex);
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
    final updatedLanes = List<BoardLaneEntity>.from(state.lanes);
    final lane = updatedLanes[laneIndex];
    final currentSlot = lane.getSlot(player);

    final updatedSlot = currentSlot.copyWith(tileAffinity: affinity);
    updatedLanes[laneIndex] = lane.copyWithSlot(player, updatedSlot);

    final placementLog = '${player.name} placed ${affinity.name.toUpperCase()} landscape in Lane $laneIndex.';
    final newLogs = [...state.logs, placementLog];

    var nextState = state.copyWith(lanes: updatedLanes, logs: newLogs);

    final allP1Placed = nextState.lanes.every((l) => l.p1Slot.tileAffinity != null);
    final allP2Placed = nextState.lanes.every((l) => l.p2Slot.tileAffinity != null);

    if (allP1Placed && allP2Placed) {
      final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(nextState.players);
      for (final pid in PlayerId.values) {
        final p = updatedPlayers[pid]!;
        final deck = List<AxieCardEntity>.from(p.deck);
        final hand = deck.take(4).toList();
        final remainingDeck = deck.skip(4).toList();
        updatedPlayers[pid] = p.copyWith(hand: hand, deck: remainingDeck);
      }

      return nextState.copyWith(
        phase: TurnPhase.turnZeroMulligan,
        activePlayer: PlayerId.p1,
        players: updatedPlayers,
        logs: [
          ...nextState.logs,
          'All 8 landscapes placed. Initial hands drawn. Mulligan phase active.',
        ],
      );
    }

    if (player == PlayerId.p1 && allP1Placed && !allP2Placed) {
      return nextState.copyWith(
        activePlayer: PlayerId.p2,
        logs: [
          ...nextState.logs,
          'P1 placed all landscapes. P2 tile placement active.',
        ],
      );
    } else if (player == PlayerId.p2 && allP2Placed && !allP1Placed) {
      return nextState.copyWith(
        activePlayer: PlayerId.p1,
        logs: [
          ...nextState.logs,
          'P2 placed all landscapes. P1 tile placement active.',
        ],
      );
    }

    return nextState;
  }

  GameState _mulligan(GameState state, PlayerId player, List<String> cardInstanceIdsToReplace) {
    final playerState = state.players[player]!;
    final hand = List<AxieCardEntity>.from(playerState.hand);
    final deck = List<AxieCardEntity>.from(playerState.deck);

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
    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    for (final pid in PlayerId.values) {
      final p = updatedPlayers[pid]!;
      updatedPlayers[pid] = p.copyWith(
        currentMana: 1,
        maxMana: 1,
        hasCompletedMulligan: true,
      );
    }

    return state.copyWith(
      roundNumber: 1,
      phase: TurnPhase.p1Turn,
      activePlayer: PlayerId.p1,
      players: updatedPlayers,
      logs: [
        ...state.logs,
        '[Round 1] Turn Zero concluded. Round 1 initiated with 1 Mana.'
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

  GameState _playBuilding(GameState state, PlayerId player, BoardBuildingEntity building, int laneIndex) {
    final updatedLanes = List<BoardLaneEntity>.from(state.lanes);
    final lane = updatedLanes[laneIndex];
    final currentSlot = lane.getSlot(player);
    updatedLanes[laneIndex] = lane.copyWithSlot(
      player,
      currentSlot.copyWith(building: building),
    );
    return state.copyWith(
      lanes: updatedLanes,
      logs: [
        ...state.logs,
        '[Play] ${player.name.toUpperCase()} placed building "${building.name}" into Lane $laneIndex.',
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
    for (final player in [PlayerId.p1, PlayerId.p2]) {
      final playerState = currentState.players[player]!;
      final placedAffinities = currentState.lanes
          .map((l) => l.getSlot(player).tileAffinity)
          .whereType<BoardClassAffinity>()
          .toList();
      final unplacedAffinities = List<BoardClassAffinity>.from(playerState.landscapeDeck);
      for (final placed in placedAffinities) {
        unplacedAffinities.remove(placed);
      }

      for (var i = 0; i < currentState.lanes.length; i++) {
        if (currentState.lanes[i].getSlot(player).tileAffinity == null && unplacedAffinities.isNotEmpty) {
          final affinity = unplacedAffinities.removeAt(0);
          currentState = _placeTile(currentState, player, i, affinity);
        }
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
        return state.copyWith(
          phase: TurnPhase.p2Turn,
          activePlayer: PlayerId.p2,
          logs: [
            ...state.logs,
            '[FSM] P1 passed turn. Active player: P2.',
          ],
        );
      case TurnPhase.p2Turn:
        final hasPlayableReactionCard = state.p1.hand.any((card) => card.manaCost <= state.p1.currentMana);
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
        return postClash.copyWith(
          phase: TurnPhase.roundEnd,
          logs: [
            ...postClash.logs,
            '[FSM] Clash resolution finished -> Transitioning to Round End.',
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
      '[Round $newRoundNumber] Round start. Mana pool set to $maxMana.'
    ];

    int p1Hp = state.p1.heroHp;
    int p2Hp = state.p2.heroHp;

    for (final pid in PlayerId.values) {
      final p = updatedPlayers[pid]!;
      final newDeck = List<AxieCardEntity>.from(p.deck);
      final newHand = List<AxieCardEntity>.from(p.hand);

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

    final updatedLanes = state.lanes.map((lane) {
      var p1o = lane.p1Slot.occupant;
      var p2o = lane.p2Slot.occupant;
      if (p1o != null) p1o = p1o.copyWith(hasFlooped: false);
      if (p2o != null) p2o = p2o.copyWith(hasFlooped: false);
      return lane.copyWith(
        p1Slot: lane.p1Slot.copyWith(occupant: p1o),
        p2Slot: lane.p2Slot.copyWith(occupant: p2o),
      );
    }).toList();

    PlayerId? winner = state.winner;
    TurnPhase phase = TurnPhase.p1Turn;

    if (winner == null) {
      if (p1Hp <= 0 && p2Hp <= 0) {
        winner = PlayerId.p2;
        phase = TurnPhase.gameOver;
        roundLogs.add('[Terminal] Both heroes perished to fatigue. Winner: P2.');
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
      activePlayer: PlayerId.p1,
      players: updatedPlayers,
      lanes: updatedLanes,
      p1UnitDestroyedInP2Turn: false,
      winner: winner,
      logs: [...state.logs, ...roundLogs],
    );
  }

  GameState resolveClashPhase(GameState state) {
    var p1Hp = state.p1.heroHp;
    var p2Hp = state.p2.heroHp;

    final p1Grave = List<BoardUnitEntity>.from(state.p1.graveyard);
    final p2Grave = List<BoardUnitEntity>.from(state.p2.graveyard);

    final nextLanes = <BoardLaneEntity>[];
    final clashLogs = <String>['[FSM] Resolving 4-Lane Simultaneous Clash Phase.'];

    for (var i = 0; i < state.lanes.length; i++) {
      final lane = state.lanes[i];
      var p1Unit = lane.p1Slot.occupant;
      var p2Unit = lane.p2Slot.occupant;
      var p1Bldg = lane.p1Slot.building;
      var p2Bldg = lane.p2Slot.building;

      // 1. Crit Check: currentPips == maxPips -> damage = floor(currentAtk * 1.25), pips = 0; else damage = currentAtk, pips = min(maxPips, pips + 1)
      int p1Dmg = 0;
      if (p1Unit != null) {
        final isCrit = p1Unit.maxPips > 0 && p1Unit.currentPips >= p1Unit.maxPips;
        if (isCrit) {
          p1Dmg = (p1Unit.currentAtk * 1.25).floor();
          p1Unit = p1Unit.copyWith(currentPips: 0);
          clashLogs.add('[Clash Step 1 - Lane $i] P1 Unit "${p1Unit.name}" CRIT! Dealt $p1Dmg dmg (pips reset to 0/${p1Unit.maxPips}).');
        } else {
          p1Dmg = p1Unit.currentAtk;
          final nextPips = min(p1Unit.maxPips, p1Unit.currentPips + 1);
          p1Unit = p1Unit.copyWith(currentPips: nextPips);
          clashLogs.add('[Clash Step 1 - Lane $i] P1 Unit "${p1Unit.name}" attack: $p1Dmg dmg (pips: $nextPips/${p1Unit.maxPips}).');
        }
      }

      int p2Dmg = 0;
      if (p2Unit != null) {
        final isCrit = p2Unit.maxPips > 0 && p2Unit.currentPips >= p2Unit.maxPips;
        if (isCrit) {
          p2Dmg = (p2Unit.currentAtk * 1.25).floor();
          p2Unit = p2Unit.copyWith(currentPips: 0);
          clashLogs.add('[Clash Step 1 - Lane $i] P2 Unit "${p2Unit.name}" CRIT! Dealt $p2Dmg dmg (pips reset to 0/${p2Unit.maxPips}).');
        } else {
          p2Dmg = p2Unit.currentAtk;
          final nextPips = min(p2Unit.maxPips, p2Unit.currentPips + 1);
          p2Unit = p2Unit.copyWith(currentPips: nextPips);
          clashLogs.add('[Clash Step 1 - Lane $i] P2 Unit "${p2Unit.name}" attack: $p2Dmg dmg (pips: $nextPips/${p2Unit.maxPips}).');
        }
      }

      // 2. Simultaneous cross
      clashLogs.add('[Clash Step 2 - Lane $i] Simultaneous cross: P1 strikes with $p1Dmg | P2 strikes with $p2Dmg.');

      // 3. Trample cascade: Unit DEF -> Lane Building (reduced by armorReduction) -> Hero HP
      // Deal P1's damage to P2 side
      if (p1Dmg > 0) {
        if (p2Unit != null) {
          if (p1Dmg > p2Unit.currentDef) {
            final overflow = p1Dmg - p2Unit.currentDef;
            p2Unit = p2Unit.copyWith(currentDef: 0);
            clashLogs.add('[Clash Step 3 - Lane $i] P1 unit broke P2 unit DEF. Overflow: $overflow.');
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
            p2Unit = p2Unit.copyWith(currentDef: p2Unit.currentDef - p1Dmg);
            clashLogs.add('[Clash Step 3 - Lane $i] P2 unit absorbed $p1Dmg damage (DEF: ${p2Unit.currentDef}/${p2Unit.maxDef}).');
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

      // Deal P2's damage to P1 side
      if (p2Dmg > 0) {
        if (p1Unit != null) {
          if (p2Dmg > p1Unit.currentDef) {
            final overflow = p2Dmg - p1Unit.currentDef;
            p1Unit = p1Unit.copyWith(currentDef: 0);
            clashLogs.add('[Clash Step 3 - Lane $i] P2 unit broke P1 unit DEF. Overflow: $overflow.');
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
            p1Unit = p1Unit.copyWith(currentDef: p1Unit.currentDef - p2Dmg);
            clashLogs.add('[Clash Step 3 - Lane $i] P1 unit absorbed $p2Dmg damage (DEF: ${p1Unit.currentDef}/${p1Unit.maxDef}).');
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

      // 4. Graveyard reaping: units/buildings with DEF/HP <= 0 moved to graveyard
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

      nextLanes.add(lane.copyWith(
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
      ));
    }

    // 5. Terminal evaluation: if any hero <= 0 HP, set winner and transition to TurnPhase.gameOver
    PlayerId? winner = state.winner;
    if (winner == null) {
      if (p1Hp <= 0 && p2Hp <= 0) {
        winner = PlayerId.p2;
      } else if (p1Hp <= 0) {
        winner = PlayerId.p2;
      } else if (p2Hp <= 0) {
        winner = PlayerId.p1;
      }
    }

    final phase = winner != null ? TurnPhase.gameOver : state.phase;
    if (winner != null) {
      clashLogs.add('[Clash Step 5] Terminal evaluation: Lethal damage reached! Winner is ${winner.name.toUpperCase()}. Phase: gameOver.');
    } else {
      clashLogs.add('[Clash Step 5] Terminal evaluation: Both heroes survive (P1 HP: $p1Hp, P2 HP: $p2Hp).');
    }

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    updatedPlayers[PlayerId.p1] = state.p1.copyWith(heroHp: p1Hp, graveyard: p1Grave);
    updatedPlayers[PlayerId.p2] = state.p2.copyWith(heroHp: p2Hp, graveyard: p2Grave);

    return state.copyWith(
      lanes: nextLanes,
      players: updatedPlayers,
      phase: phase,
      winner: winner,
      logs: [...state.logs, ...clashLogs],
    );
  }
}
