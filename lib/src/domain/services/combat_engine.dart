// ===============================================================================
// [MODULE_NAME]: combat_engine.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Services
// [INTENT]: Pure deterministic engine for combat rules, interleaved drafting, priority inversion, tactical buildings, floops, spells, and early lethal short-circuit
// [DEPENDENCIES]: ../entities/combat/combat_enums.dart, ../entities/combat/game_state.dart, ../entities/combat/player_state_entity.dart, ../entities/combat/board_lane_entity.dart, ../entities/combat/game_action.dart, ../entities/combat/board_unit_entity.dart, ../entities/combat/board_building_entity.dart, ../entities/combat/building_card_entity.dart, ../entities/combat/spell_card_entity.dart, ../entities/combat/floop_ability_entity.dart, ../entities/combat/combat_card.dart, ../entities/axie_card_entity.dart, axie_card_factory.dart
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
import '../entities/combat/spell_card_entity.dart';
import '../entities/combat/floop_ability_entity.dart';
import '../entities/combat/combat_card.dart';
import '../entities/axie_card_entity.dart';
import 'axie_card_factory.dart';

class CombatEngine {
  GameState initializeGame({
    List<CombatCard>? p1Deck,
    List<CombatCard>? p2Deck,
    List<BoardClassAffinity>? p1Landscapes,
    List<BoardClassAffinity>? p2Landscapes,
    PlayerId initialActivePlayer = PlayerId.p1,
  }) {
    final effectiveP1Deck = p1Deck ?? AxieCardFactory.createCanonicalDeck('p1');
    final effectiveP2Deck = p2Deck ?? AxieCardFactory.createCanonicalDeck('p2');

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
      deck: List<CombatCard>.from(effectiveP1Deck),
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
      deck: List<CombatCard>.from(effectiveP2Deck),
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

  GameState drawCard(GameState state, PlayerId player) {
    final p = state.players[player]!;
    if (p.deck.isEmpty) {
      final newHp = p.heroHp - 5;
      final updatedPlayer = p.copyWith(heroHp: newHp);
      final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
      updatedPlayers[player] = updatedPlayer;

      final logMsg = '[Fatigue Penalty] ${player.name.toUpperCase()} deck is empty! Suffered -5 HP fatigue damage (HP: $newHp).';

      PlayerId? winner = state.winner;
      TurnPhase phase = state.phase;
      if (newHp <= 0 && winner == null) {
        final opponent = (player == PlayerId.p1) ? PlayerId.p2 : PlayerId.p1;
        winner = opponent;
        phase = TurnPhase.gameOver;
      }

      return state.copyWith(
        players: updatedPlayers,
        winner: winner,
        phase: phase,
        logs: [...state.logs, logMsg],
      );
    }

    final drawnCard = p.deck.first;
    final remainingDeck = p.deck.sublist(1);

    if (p.hand.length < PlayerStateEntity.maxHandCapacity) {
      final newHand = [...p.hand, drawnCard];
      final updatedPlayer = p.copyWith(hand: newHand, deck: remainingDeck);
      final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
      updatedPlayers[player] = updatedPlayer;

      final logMsg = '[Draw] ${player.name.toUpperCase()} drew "${drawnCard.name}". Hand: ${newHand.length}/${PlayerStateEntity.maxHandCapacity}.';
      return state.copyWith(
        players: updatedPlayers,
        logs: [...state.logs, logMsg],
      );
    } else {
      // Overdraw penalty: card sent to bottom of deck without shuffle! Hand remains unchanged.
      final newDeck = [...remainingDeck, drawnCard];
      final updatedPlayer = p.copyWith(deck: newDeck);
      final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
      updatedPlayers[player] = updatedPlayer;

      final logMsg = 'OVERDRAW PENALTY: Player ${player.name} hand is full (7/7). Card [${drawnCard.name}] sent to bottom of deck.';
      return state.copyWith(
        players: updatedPlayers,
        logs: [...state.logs, logMsg],
      );
    }
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
      // Spells
      for (final card in playerState.spellHand) {
        if (playerState.currentMana >= card.manaCost) {
          for (var i = 0; i < state.lanes.length; i++) {
            actions.add(PlaySpellAction(
              player: player,
              cardInstanceId: card.id,
              targetLaneIndex: i,
            ));
          }
        }
      }
      // Floop
      for (var i = 0; i < state.lanes.length; i++) {
        final slot = state.lanes[i].getSlot(player);
        if (slot.occupant != null &&
            !slot.hasFloopedThisRound &&
            slot.occupant!.floop != null &&
            playerState.currentMana >= slot.occupant!.floop!.manaCost) {
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
      PlaySpellAction a => a.player,
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
        } else if (action is PlaySpellAction && legalAction is PlaySpellAction) {
          if (action.cardInstanceId == legalAction.cardInstanceId && action.targetLaneIndex == legalAction.targetLaneIndex) {
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
      case PlaySpellAction a:
        newState = _playSpell(newState, a.player, a.cardInstanceId, a.targetLaneIndex, a.targetPlayer);
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

    // Reinsert discarded cards back into player deck
    final deckWithReinserted = [...deck, ...cardsToReplace];

    // Seeded deterministic shuffle
    final seed = state.roundNumber * 31 + cardInstanceIdsToReplace.length * 17 + player.index;
    final rng = Random(seed);
    deckWithReinserted.shuffle(rng);

    // Draw replacement cards equal to discarded count
    final countToDraw = cardsToReplace.length;
    final drawnCards = deckWithReinserted.take(countToDraw).toList();
    final remainingDeck = deckWithReinserted.skip(countToDraw).toList();

    final newHand = [...remainingHand, ...drawnCards];
    final updatedPlayer = playerState.copyWith(
      hand: newHand,
      deck: remainingDeck,
      hasCompletedMulligan: true,
    );

    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    updatedPlayers[player] = updatedPlayer;

    final logMsg = '[Turn Zero] ${player.name.toUpperCase()} mulliganed ${cardsToReplace.length} card(s). Deck reshuffled with seeded RNG.';
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

  GameState _playSpell(GameState state, PlayerId player, String cardInstanceId, int targetLaneIndex, PlayerId? targetPlayer) {
    final playerState = state.players[player]!;
    final cardIndex = playerState.hand.indexWhere((c) => c.id == cardInstanceId);
    if (cardIndex == -1) return state;
    final card = playerState.hand[cardIndex];
    if (card is! SpellCardEntity) return state;
    if (playerState.currentMana < card.manaCost) return state;

    final updatedHand = List<CombatCard>.from(playerState.hand)..removeAt(cardIndex);
    final updatedMana = playerState.currentMana - card.manaCost;
    final updatedGrave = List<BoardUnitEntity>.from(playerState.graveyard);

    final updatedLanes = List<BoardLaneEntity>.from(state.lanes);
    final lane = updatedLanes[targetLaneIndex];
    final logs = <String>[];
    logs.add('[Spell] ${player.name.toUpperCase()} cast "${card.name}" on Lane $targetLaneIndex.');

    final opponent = (player == PlayerId.p1) ? PlayerId.p2 : PlayerId.p1;
    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);

    var laneSlotP1 = lane.p1Slot;
    var laneSlotP2 = lane.p2Slot;

    switch (card.effectType) {
      case SpellEffectType.grantDef:
        final alliedSlot = (player == PlayerId.p1) ? laneSlotP1 : laneSlotP2;
        final occupant = alliedSlot.occupant;
        if (occupant != null) {
          final missingDef = occupant.maxDef - occupant.currentDef;
          final heal = min(missingDef, card.effectValue);
          final buffed = occupant.copyWith(currentDef: occupant.currentDef + heal);
          if (player == PlayerId.p1) {
            laneSlotP1 = laneSlotP1.copyWith(occupant: buffed);
          } else {
            laneSlotP2 = laneSlotP2.copyWith(occupant: buffed);
          }
          logs.add('[Spell Effect] "${occupant.name}" restored +$heal DEF (now ${buffed.currentDef}/${occupant.maxDef}).');
        }
        break;

      case SpellEffectType.grantAtk:
        final alliedSlot = (player == PlayerId.p1) ? laneSlotP1 : laneSlotP2;
        final occupant = alliedSlot.occupant;
        if (occupant != null) {
          final buffed = occupant.copyWith(currentAtk: occupant.currentAtk + card.effectValue);
          if (player == PlayerId.p1) {
            laneSlotP1 = laneSlotP1.copyWith(occupant: buffed);
          } else {
            laneSlotP2 = laneSlotP2.copyWith(occupant: buffed);
          }
          logs.add('[Spell Effect] "${occupant.name}" gained +${card.effectValue} ATK (now ${buffed.baseAtk}).');
        }
        break;

      case SpellEffectType.directDamage:
        final enemySlot = (player == PlayerId.p1) ? laneSlotP2 : laneSlotP1;
        final occupant = enemySlot.occupant;
        if (occupant != null) {
          final newDef = occupant.currentDef - card.effectValue;
          if (newDef <= 0) {
            logs.add('[Spell Effect] Direct damage ${card.effectValue} destroyed enemy unit "${occupant.name}".');
            final oppState = updatedPlayers[opponent]!;
            updatedPlayers[opponent] = oppState.copyWith(
              graveyard: [...oppState.graveyard, occupant],
            );
            if (opponent == PlayerId.p1) {
              laneSlotP1 = laneSlotP1.copyWith(clearOccupant: true);
            } else {
              laneSlotP2 = laneSlotP2.copyWith(clearOccupant: true);
            }
          } else {
            final damaged = occupant.copyWith(currentDef: newDef);
            if (opponent == PlayerId.p1) {
              laneSlotP1 = laneSlotP1.copyWith(occupant: damaged);
            } else {
              laneSlotP2 = laneSlotP2.copyWith(occupant: damaged);
            }
            logs.add('[Spell Effect] Direct damage ${card.effectValue} hit enemy unit "${occupant.name}" (DEF: $newDef/${occupant.baseDef}).');
          }
        }
        break;

      case SpellEffectType.repairBuilding:
        final alliedSlot = (player == PlayerId.p1) ? laneSlotP1 : laneSlotP2;
        final building = alliedSlot.building;
        if (building != null) {
          final newHp = min(building.maxHp, building.currentHp + card.effectValue);
          final repaired = building.copyWith(currentHp: newHp);
          if (player == PlayerId.p1) {
            laneSlotP1 = laneSlotP1.copyWith(building: repaired);
          } else {
            laneSlotP2 = laneSlotP2.copyWith(building: repaired);
          }
          logs.add('[Spell Effect] Building "${building.name}" repaired for +${card.effectValue} HP (now $newHp/${building.maxHp}).');
        }
        break;
    }

    updatedLanes[targetLaneIndex] = lane.copyWith(p1Slot: laneSlotP1, p2Slot: laneSlotP2);
    updatedPlayers[player] = playerState.copyWith(
      hand: updatedHand,
      currentMana: updatedMana,
      graveyard: updatedGrave,
    );

    return state.copyWith(
      lanes: updatedLanes,
      players: updatedPlayers,
      logs: [...state.logs, ...logs],
    );
  }

  GameState _activateFloop(GameState state, PlayerId player, int laneIndex) {
    final updatedLanes = List<BoardLaneEntity>.from(state.lanes);
    final lane = updatedLanes[laneIndex];
    final currentSlot = lane.getSlot(player);
    final unit = currentSlot.occupant;
    if (unit == null) return state;
    if (currentSlot.hasFloopedThisRound) return state;

    final playerState = state.players[player]!;
    final floop = unit.floop;
    final manaCost = floop?.manaCost ?? 0;
    if (playerState.currentMana < manaCost) return state;

    final updatedMana = playerState.currentMana - manaCost;
    final updatedPlayers = Map<PlayerId, PlayerStateEntity>.from(state.players);
    updatedPlayers[player] = playerState.copyWith(currentMana: updatedMana);

    final logs = <String>[];
    logs.add('[Floop] ${player.name.toUpperCase()} activated Floop "${floop?.name ?? "Basic Floop"}" in Lane $laneIndex.');

    BoardUnitEntity updatedUnit = unit.copyWith(hasFlooped: true);
    final opponent = (player == PlayerId.p1) ? PlayerId.p2 : PlayerId.p1;
    var oppPlayerState = updatedPlayers[opponent]!;

    var laneSlotP1 = lane.p1Slot;
    var laneSlotP2 = lane.p2Slot;

    if (floop != null) {
      switch (floop.effectType) {
        case FloopEffectType.buffAtk:
          updatedUnit = updatedUnit.copyWith(currentAtk: updatedUnit.currentAtk + floop.effectValue);
          logs.add('[Floop Effect] "${updatedUnit.name}" gained +${floop.effectValue} ATK (now ${updatedUnit.baseAtk}).');
          break;

        case FloopEffectType.restoreDef:
          final missingDef = updatedUnit.baseDef - updatedUnit.currentDef;
          final heal = min(missingDef, floop.effectValue);
          if (heal > 0) {
            updatedUnit = updatedUnit.copyWith(currentDef: updatedUnit.currentDef + heal);
            logs.add('[Floop Effect] "${updatedUnit.name}" restored +$heal DEF (now ${updatedUnit.currentDef}/${updatedUnit.baseDef}).');
          }
          break;

        case FloopEffectType.debuffEnemyAtk:
          final oppSlot = lane.getSlot(opponent);
          final oppOccupant = oppSlot.occupant;
          if (oppOccupant != null) {
            final newAtk = max(0, oppOccupant.baseAtk - floop.effectValue);
            final debuffed = oppOccupant.copyWith(currentAtk: newAtk);
            if (opponent == PlayerId.p1) {
              laneSlotP1 = laneSlotP1.copyWith(occupant: debuffed);
            } else {
              laneSlotP2 = laneSlotP2.copyWith(occupant: debuffed);
            }
            logs.add('[Floop Effect] Enemy "${oppOccupant.name}" debuffed by -${floop.effectValue} ATK (now $newAtk).');
          }
          break;

        case FloopEffectType.directDamage:
          final oppSlot = lane.getSlot(opponent);
          final oppOccupant = oppSlot.occupant;
          final oppBuilding = oppSlot.building;

          if (oppOccupant != null) {
            final dmg = floop.effectValue;
            if (dmg >= oppOccupant.currentDef) {
              final overflow = dmg - oppOccupant.currentDef;
              logs.add('[Floop Effect] Direct damage $dmg destroyed enemy unit "${oppOccupant.name}" (Overflow: $overflow).');
              final oppGrave = [...oppPlayerState.graveyard, oppOccupant];
              oppPlayerState = oppPlayerState.copyWith(graveyard: oppGrave);

              if (opponent == PlayerId.p1) {
                laneSlotP1 = laneSlotP1.copyWith(clearOccupant: true);
              } else {
                laneSlotP2 = laneSlotP2.copyWith(clearOccupant: true);
              }

              if (overflow > 0) {
                if (oppBuilding != null) {
                  final actualBldgDmg = max(0, overflow - oppBuilding.armorReduction);
                  if (actualBldgDmg >= oppBuilding.currentHp) {
                    final residual = actualBldgDmg - oppBuilding.currentHp;
                    if (opponent == PlayerId.p1) {
                      laneSlotP1 = laneSlotP1.copyWith(clearBuilding: true);
                    } else {
                      laneSlotP2 = laneSlotP2.copyWith(clearBuilding: true);
                    }
                    final newHp = oppPlayerState.heroHp - residual;
                    oppPlayerState = oppPlayerState.copyWith(heroHp: newHp);
                    logs.add('[Floop Effect] Overflow destroyed building "${oppBuilding.name}". Residual $residual dealt to Hero (HP: $newHp).');
                  } else {
                    final newBldgHp = oppBuilding.currentHp - actualBldgDmg;
                    final updatedBldg = oppBuilding.copyWith(currentHp: newBldgHp);
                    if (opponent == PlayerId.p1) {
                      laneSlotP1 = laneSlotP1.copyWith(building: updatedBldg);
                    } else {
                      laneSlotP2 = laneSlotP2.copyWith(building: updatedBldg);
                    }
                  }
                } else {
                  final newHp = oppPlayerState.heroHp - overflow;
                  oppPlayerState = oppPlayerState.copyWith(heroHp: newHp);
                  logs.add('[Floop Effect] Residual overflow $overflow dealt to enemy Hero (HP: $newHp).');
                }
              }
            } else {
              final newDef = oppOccupant.currentDef - dmg;
              final damaged = oppOccupant.copyWith(currentDef: newDef);
              if (opponent == PlayerId.p1) {
                laneSlotP1 = laneSlotP1.copyWith(occupant: damaged);
              } else {
                laneSlotP2 = laneSlotP2.copyWith(occupant: damaged);
              }
              logs.add('[Floop Effect] Direct damage $dmg hit enemy unit "${oppOccupant.name}" (DEF: $newDef/${oppOccupant.baseDef}).');
            }
          } else if (oppBuilding != null) {
            final actualBldgDmg = max(0, floop.effectValue - oppBuilding.armorReduction);
            if (actualBldgDmg >= oppBuilding.currentHp) {
              final residual = actualBldgDmg - oppBuilding.currentHp;
              if (opponent == PlayerId.p1) {
                laneSlotP1 = laneSlotP1.copyWith(clearBuilding: true);
              } else {
                laneSlotP2 = laneSlotP2.copyWith(clearBuilding: true);
              }
              final newHp = oppPlayerState.heroHp - residual;
              oppPlayerState = oppPlayerState.copyWith(heroHp: newHp);
              logs.add('[Floop Effect] Floop direct damage destroyed building "${oppBuilding.name}". Residual $residual dealt to Hero (HP: $newHp).');
            } else {
              final newBldgHp = oppBuilding.currentHp - actualBldgDmg;
              final updatedBldg = oppBuilding.copyWith(currentHp: newBldgHp);
              if (opponent == PlayerId.p1) {
                laneSlotP1 = laneSlotP1.copyWith(building: updatedBldg);
              } else {
                laneSlotP2 = laneSlotP2.copyWith(building: updatedBldg);
              }
            }
          } else {
            final newHp = oppPlayerState.heroHp - floop.effectValue;
            oppPlayerState = oppPlayerState.copyWith(heroHp: newHp);
            logs.add('[Floop Effect] Floop direct strike dealt ${floop.effectValue} to enemy Hero (HP: $newHp).');
          }
          break;
      }
    }

    updatedPlayers[opponent] = oppPlayerState;

    if (player == PlayerId.p1) {
      laneSlotP1 = laneSlotP1.copyWith(occupant: updatedUnit, hasFloopedThisRound: true);
    } else {
      laneSlotP2 = laneSlotP2.copyWith(occupant: updatedUnit, hasFloopedThisRound: true);
    }

    updatedLanes[laneIndex] = lane.copyWith(p1Slot: laneSlotP1, p2Slot: laneSlotP2);

    PlayerId? winner = state.winner;
    TurnPhase phase = state.phase;
    if (oppPlayerState.heroHp <= 0 && winner == null) {
      winner = player;
      phase = TurnPhase.gameOver;
      logs.add('[Terminal] Opposing hero perished to Floop ability! Winner: ${player.name.toUpperCase()}.');
    }

    return state.copyWith(
      lanes: updatedLanes,
      players: updatedPlayers,
      winner: winner,
      phase: phase,
      logs: [...state.logs, ...logs],
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
    for (final pid in PlayerId.values) {
      final p = updatedPlayers[pid]!;
      updatedPlayers[pid] = p.copyWith(
        currentMana: maxMana,
        maxMana: maxMana,
      );
    }

    var currentState = state.copyWith(
      roundNumber: newRoundNumber,
      players: updatedPlayers,
      logs: [
        ...state.logs,
        '[Round $newRoundNumber] Round start. Mana pool set to $maxMana. Initiative player: ${state.initiativePlayer.name.toUpperCase()}.',
      ],
    );

    // Draw cards with 7-card ceiling & overdraw penalty
    for (final pid in PlayerId.values) {
      currentState = drawCard(currentState, pid);
    }

    // Lane occupants: reset floop & execute Round Start Repair hook
    final updatedLanes = currentState.lanes.map((lane) {
      var p1o = lane.p1Slot.occupant;
      var p2o = lane.p2Slot.occupant;
      final p1b = lane.p1Slot.building;
      final p2b = lane.p2Slot.building;

      final roundLogs = <String>[];
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
        p1Slot: lane.p1Slot.copyWith(
          occupant: p1o,
          hasFloopedThisRound: false,
        ),
        p2Slot: lane.p2Slot.copyWith(
          occupant: p2o,
          hasFloopedThisRound: false,
        ),
      );
    }).toList();

    PlayerId? winner = currentState.winner;
    TurnPhase phase = (currentState.initiativePlayer == PlayerId.p1) ? TurnPhase.p1Turn : TurnPhase.p2Turn;
    if (winner != null) {
      phase = TurnPhase.gameOver;
    }

    return currentState.copyWith(
      phase: phase,
      activePlayer: currentState.initiativePlayer,
      lanes: updatedLanes,
      p1UnitDestroyedInP2Turn: false,
      winner: winner,
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
