// ===============================================================================
// [MODULE_NAME]: building_card_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Tactical building cards implementing CombatCard with persistent auras and repair effects
// [DEPENDENCIES]: combat_card.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'combat_card.dart';

enum BuildingEffectType {
  attackAura,
  defenseAura,
  roundStartRepair,
}

class BuildingCardEntity implements CombatCard {
  @override
  final String id;
  @override
  final String name;
  @override
  final int manaCost;
  final int maxHp;
  final int armorReduction;
  final BuildingEffectType effectType;
  final int effectValue;

  const BuildingCardEntity({
    required this.id,
    required this.name,
    required this.manaCost,
    required this.maxHp,
    required this.armorReduction,
    required this.effectType,
    required this.effectValue,
  });

  BuildingCardEntity copyWith({
    String? id,
    String? name,
    int? manaCost,
    int? maxHp,
    int? armorReduction,
    BuildingEffectType? effectType,
    int? effectValue,
  }) {
    return BuildingCardEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      manaCost: manaCost ?? this.manaCost,
      maxHp: maxHp ?? this.maxHp,
      armorReduction: armorReduction ?? this.armorReduction,
      effectType: effectType ?? this.effectType,
      effectValue: effectValue ?? this.effectValue,
    );
  }

  factory BuildingCardEntity.attackTotem({String? id}) {
    return BuildingCardEntity(
      id: id ?? 'bldg_atk_totem',
      name: 'Attack Totem',
      manaCost: 2,
      maxHp: 12,
      armorReduction: 1,
      effectType: BuildingEffectType.attackAura,
      effectValue: 2,
    );
  }

  factory BuildingCardEntity.defenseBarricade({String? id}) {
    return BuildingCardEntity(
      id: id ?? 'bldg_def_barricade',
      name: 'Defense Barricade',
      manaCost: 2,
      maxHp: 16,
      armorReduction: 2,
      effectType: BuildingEffectType.defenseAura,
      effectValue: 5,
    );
  }

  factory BuildingCardEntity.vitalityShrine({String? id}) {
    return BuildingCardEntity(
      id: id ?? 'bldg_vitality_shrine',
      name: 'Vitality Shrine',
      manaCost: 3,
      maxHp: 14,
      armorReduction: 1,
      effectType: BuildingEffectType.roundStartRepair,
      effectValue: 8,
    );
  }
}
