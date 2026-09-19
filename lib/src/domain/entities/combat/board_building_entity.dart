// ===============================================================================
// [MODULE_NAME]: board_building_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Represents a building currently deployed on the board with defensive armor and aura effects
// [DEPENDENCIES]: building_card_entity.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'building_card_entity.dart';

class BoardBuildingEntity {
  final String instanceId;
  final String name;
  final int currentHp;
  final int maxHp;
  final int armorReduction;
  final BuildingEffectType? effectType;
  final int effectValue;

  const BoardBuildingEntity({
    required this.instanceId,
    required this.name,
    required this.currentHp,
    required this.maxHp,
    required this.armorReduction,
    this.effectType,
    this.effectValue = 0,
  });

  factory BoardBuildingEntity.fromCard(
    BuildingCardEntity card, {
    required String instanceId,
  }) {
    return BoardBuildingEntity(
      instanceId: instanceId,
      name: card.name,
      currentHp: card.maxHp,
      maxHp: card.maxHp,
      armorReduction: card.armorReduction,
      effectType: card.effectType,
      effectValue: card.effectValue,
    );
  }

  BoardBuildingEntity copyWith({
    String? instanceId,
    String? name,
    int? currentHp,
    int? maxHp,
    int? armorReduction,
    BuildingEffectType? effectType,
    int? effectValue,
    bool clearEffectType = false,
  }) {
    return BoardBuildingEntity(
      instanceId: instanceId ?? this.instanceId,
      name: name ?? this.name,
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      armorReduction: armorReduction ?? this.armorReduction,
      effectType: clearEffectType ? null : (effectType ?? this.effectType),
      effectValue: effectValue ?? this.effectValue,
    );
  }
}
