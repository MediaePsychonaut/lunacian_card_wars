// ===============================================================================
// [MODULE_NAME]: spell_card_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Tactical one-shot spell cards implementing CombatCard
// [DEPENDENCIES]: combat_card.dart, equatable.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'combat_card.dart';
import 'equatable.dart';

enum SpellTargetType {
  alliedUnit,
  enemyUnit,
  enemyHero,
  laneSlot,
}

enum SpellEffectType {
  directDamage,
  grantDef,
  grantAtk,
  repairBuilding,
}

class SpellCardEntity extends Equatable implements CombatCard {
  @override
  final String id;
  @override
  final String name;
  @override
  final int manaCost;
  final SpellTargetType targetType;
  final SpellEffectType effectType;
  final int effectValue;
  final String description;

  const SpellCardEntity({
    required this.id,
    required this.name,
    required this.manaCost,
    required this.targetType,
    required this.effectType,
    required this.effectValue,
    required this.description,
  });

  SpellCardEntity copyWith({
    String? id,
    String? name,
    int? manaCost,
    SpellTargetType? targetType,
    SpellEffectType? effectType,
    int? effectValue,
    String? description,
  }) {
    return SpellCardEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      manaCost: manaCost ?? this.manaCost,
      targetType: targetType ?? this.targetType,
      effectType: effectType ?? this.effectType,
      effectValue: effectValue ?? this.effectValue,
      description: description ?? this.description,
    );
  }

  factory SpellCardEntity.potionOfVitality({String id = 'spell_vitality_potion'}) {
    return SpellCardEntity(
      id: id,
      name: 'Potion of Vitality',
      manaCost: 1,
      targetType: SpellTargetType.alliedUnit,
      effectType: SpellEffectType.grantDef,
      effectValue: 6,
      description: 'Grants +6 DEF (capped at maxDef) to allied unit.',
    );
  }

  factory SpellCardEntity.starShuriken({String id = 'spell_star_shuriken'}) {
    return SpellCardEntity(
      id: id,
      name: 'Star Shuriken',
      manaCost: 2,
      targetType: SpellTargetType.enemyUnit,
      effectType: SpellEffectType.directDamage,
      effectValue: 5,
      description: 'Deals 5 direct unmitigated damage to enemy unit.',
    );
  }

  factory SpellCardEntity.lunarBlessing({String id = 'spell_lunar_blessing'}) {
    return SpellCardEntity(
      id: id,
      name: 'Lunar Blessing',
      manaCost: 2,
      targetType: SpellTargetType.alliedUnit,
      effectType: SpellEffectType.grantAtk,
      effectValue: 3,
      description: 'Grants +3 persistent ATK to allied unit.',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        manaCost,
        targetType,
        effectType,
        effectValue,
        description,
      ];
}
