// ===============================================================================
// [MODULE_NAME]: game_state.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Root snapshot of the combat game state
// [DEPENDENCIES]: combat_enums.dart, player_state_entity.dart, board_lane_entity.dart, game_action.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'combat_enums.dart';
import 'player_state_entity.dart';
import 'board_lane_entity.dart';
import 'game_action.dart';

class GameState {
  final int roundNumber;
  final TurnPhase phase;
  final PlayerId activePlayer;
  final PlayerId initiativePlayer;
  final Map<PlayerId, PlayerStateEntity> players;
  final List<BoardLaneEntity> lanes;
  final List<GameAction> actionHistory;
  final List<String> logs;
  final PlayerId? winner;
  final bool p1UnitDestroyedInP2Turn;

  const GameState({
    required this.roundNumber,
    required this.phase,
    required this.activePlayer,
    this.initiativePlayer = PlayerId.p1,
    required this.players,
    required this.lanes,
    required this.actionHistory,
    this.logs = const [],
    this.winner,
    this.p1UnitDestroyedInP2Turn = false,
  });

  PlayerStateEntity get activePlayerState => players[activePlayer]!;
  PlayerStateEntity get p1 => players[PlayerId.p1]!;
  PlayerStateEntity get p2 => players[PlayerId.p2]!;

  GameState copyWith({
    int? roundNumber,
    TurnPhase? phase,
    PlayerId? activePlayer,
    PlayerId? initiativePlayer,
    Map<PlayerId, PlayerStateEntity>? players,
    List<BoardLaneEntity>? lanes,
    List<GameAction>? actionHistory,
    List<String>? logs,
    PlayerId? winner,
    bool? p1UnitDestroyedInP2Turn,
    bool clearWinner = false,
  }) {
    return GameState(
      roundNumber: roundNumber ?? this.roundNumber,
      phase: phase ?? this.phase,
      activePlayer: activePlayer ?? this.activePlayer,
      initiativePlayer: initiativePlayer ?? this.initiativePlayer,
      players: players ?? this.players,
      lanes: lanes ?? this.lanes,
      actionHistory: actionHistory ?? this.actionHistory,
      logs: logs ?? this.logs,
      winner: clearWinner ? null : (winner ?? this.winner),
      p1UnitDestroyedInP2Turn: p1UnitDestroyedInP2Turn ?? this.p1UnitDestroyedInP2Turn,
    );
  }
}
