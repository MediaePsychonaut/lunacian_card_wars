// ===============================================================================
// [MODULE_NAME]: game_action.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Sealed classes for dispatched game actions
// [DEPENDENCIES]: combat_enums.dart, axie_card_entity.dart, board_building_entity.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern / Sealed Hierarchy
// ===============================================================================

import '../axie_card_entity.dart';
import 'combat_enums.dart';
import 'board_building_entity.dart';

sealed class GameAction {
  const GameAction();
}

class PlayUnitAction extends GameAction {
  final PlayerId player;
  final AxieCardEntity card;
  final int laneIndex;

  const PlayUnitAction(this.player, this.card, this.laneIndex);
}

class PlayBuildingAction extends GameAction {
  final PlayerId player;
  final BoardBuildingEntity building;
  final int laneIndex;

  const PlayBuildingAction(this.player, this.building, this.laneIndex);
}

class ActivateFloopAction extends GameAction {
  final PlayerId player;
  final int laneIndex;
  final Map<String, dynamic>? params;

  const ActivateFloopAction(this.player, this.laneIndex, {this.params});
}

class PassPhaseAction extends GameAction {
  final PlayerId player;

  const PassPhaseAction(this.player);
}

class ReactPlayAction extends GameAction {
  final PlayerId player;
  final AxieCardEntity card;
  final int laneIndex;

  const ReactPlayAction(this.player, this.card, this.laneIndex);
}

class MulliganAction extends GameAction {
  final PlayerId player;
  final List<String> cardInstanceIdsToReplace;

  const MulliganAction(this.player, this.cardInstanceIdsToReplace);
}

class PlaceTileAction extends GameAction {
  final PlayerId player;
  final int laneIndex;
  final BoardClassAffinity affinity;

  const PlaceTileAction(this.player, this.laneIndex, this.affinity);
}
