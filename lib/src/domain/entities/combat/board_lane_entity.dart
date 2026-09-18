// ===============================================================================
// [MODULE_NAME]: board_lane_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Represents a lane on the board with slots for units and buildings
// [DEPENDENCIES]: board_unit_entity.dart, board_building_entity.dart, combat_enums.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'board_unit_entity.dart';
import 'board_building_entity.dart';
import 'combat_enums.dart';

class LaneSlot {
  final BoardUnitEntity? occupant;
  final BoardBuildingEntity? building;
  final BoardClassAffinity? tileAffinity;

  const LaneSlot({
    this.occupant,
    this.building,
    this.tileAffinity,
  });

  LaneSlot copyWith({
    BoardUnitEntity? occupant,
    bool clearOccupant = false,
    BoardBuildingEntity? building,
    bool clearBuilding = false,
    BoardClassAffinity? tileAffinity,
    bool clearTileAffinity = false,
  }) {
    return LaneSlot(
      occupant: clearOccupant ? null : (occupant ?? this.occupant),
      building: clearBuilding ? null : (building ?? this.building),
      tileAffinity: clearTileAffinity ? null : (tileAffinity ?? this.tileAffinity),
    );
  }
}

class BoardLaneEntity {
  final int laneIndex;
  final LaneSlot p1Slot;
  final LaneSlot p2Slot;

  const BoardLaneEntity({
    required this.laneIndex,
    required this.p1Slot,
    required this.p2Slot,
  });

  LaneSlot getSlot(PlayerId player) => player == PlayerId.p1 ? p1Slot : p2Slot;

  BoardLaneEntity copyWithSlot(PlayerId player, LaneSlot slot) =>
      player == PlayerId.p1 ? copyWith(p1Slot: slot) : copyWith(p2Slot: slot);

  BoardLaneEntity copyWith({
    int? laneIndex,
    LaneSlot? p1Slot,
    LaneSlot? p2Slot,
  }) {
    return BoardLaneEntity(
      laneIndex: laneIndex ?? this.laneIndex,
      p1Slot: p1Slot ?? this.p1Slot,
      p2Slot: p2Slot ?? this.p2Slot,
    );
  }
}
