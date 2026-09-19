// ===============================================================================
// [MODULE_NAME]: floop_ability_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: First-class entity modeling activated Floop abilities for Axie creatures
// [DEPENDENCIES]: equatable.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'equatable.dart';

enum FloopTargetType {
  self,
  laneEnemyUnit,
  opposingHero,
  alliedLaneUnit,
}

enum FloopEffectType {
  directDamage,
  buffAtk,
  restoreDef,
  debuffEnemyAtk,
}

class FloopAbilityEntity extends Equatable {
  final String id;
  final String name;
  final int manaCost;
  final String description;
  final FloopTargetType targetRequirement;
  final FloopEffectType effectType;
  final int effectValue;

  const FloopAbilityEntity({
    required this.id,
    required this.name,
    required this.manaCost,
    required this.description,
    required this.targetRequirement,
    required this.effectType,
    required this.effectValue,
  });

  FloopAbilityEntity copyWith({
    String? id,
    String? name,
    int? manaCost,
    String? description,
    FloopTargetType? targetRequirement,
    FloopEffectType? effectType,
    int? effectValue,
  }) {
    return FloopAbilityEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      manaCost: manaCost ?? this.manaCost,
      description: description ?? this.description,
      targetRequirement: targetRequirement ?? this.targetRequirement,
      effectType: effectType ?? this.effectType,
      effectValue: effectValue ?? this.effectValue,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        manaCost,
        description,
        targetRequirement,
        effectType,
        effectValue,
      ];
}
