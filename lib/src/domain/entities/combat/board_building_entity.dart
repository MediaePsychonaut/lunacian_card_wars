// ===============================================================================
// [MODULE_NAME]: board_building_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Represents a building currently deployed on the board
// [DEPENDENCIES]: None
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

class BoardBuildingEntity {
  final String instanceId;
  final String name;
  final int currentHp;
  final int maxHp;
  final int armorReduction;

  const BoardBuildingEntity({
    required this.instanceId,
    required this.name,
    required this.currentHp,
    required this.maxHp,
    required this.armorReduction,
  });

  BoardBuildingEntity copyWith({
    String? instanceId,
    String? name,
    int? currentHp,
    int? maxHp,
    int? armorReduction,
  }) {
    return BoardBuildingEntity(
      instanceId: instanceId ?? this.instanceId,
      name: name ?? this.name,
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      armorReduction: armorReduction ?? this.armorReduction,
    );
  }
}
