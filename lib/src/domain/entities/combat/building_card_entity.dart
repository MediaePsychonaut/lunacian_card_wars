// ===============================================================================
// [MODULE_NAME]: building_card_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Tactical building cards implementing CombatCard with persistent auras, repair effects, and Lunacian class affinity contracts.
// [DEPENDENCIES]: combat_card.dart, combat_enums.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'combat_card.dart';
import 'combat_enums.dart';

enum BuildingEffectType {
  attackAura,
  defenseAura,
  roundStartRepair,
  damageTrigger,
  swapStats,
  utility,
}

class BuildingCardEntity implements CombatCard {
  @override
  final String id;
  @override
  final String name;
  final BoardClassAffinity axieClassAffinity;
  @override
  final int manaCost;
  final int maxHp;
  final int armorReduction;
  final BuildingEffectType effectType;
  final String rawEffectType;
  final int effectValue;
  final String scalingFormula;
  final String activationTrigger;
  final String targetScope;
  final String loreDescription;
  final String cardArtAssetId;

  const BuildingCardEntity({
    required this.id,
    required this.name,
    this.axieClassAffinity = BoardClassAffinity.neutral,
    required this.manaCost,
    required this.maxHp,
    required this.armorReduction,
    required this.effectType,
    this.rawEffectType = '',
    required this.effectValue,
    this.scalingFormula = 'NONE',
    this.activationTrigger = 'PASSIVE',
    this.targetScope = 'LANE_UNIT',
    this.loreDescription = '',
    this.cardArtAssetId = '',
  });

  BuildingCardEntity copyWith({
    String? id,
    String? name,
    BoardClassAffinity? axieClassAffinity,
    int? manaCost,
    int? maxHp,
    int? armorReduction,
    BuildingEffectType? effectType,
    String? rawEffectType,
    int? effectValue,
    String? scalingFormula,
    String? activationTrigger,
    String? targetScope,
    String? loreDescription,
    String? cardArtAssetId,
  }) {
    return BuildingCardEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      axieClassAffinity: axieClassAffinity ?? this.axieClassAffinity,
      manaCost: manaCost ?? this.manaCost,
      maxHp: maxHp ?? this.maxHp,
      armorReduction: armorReduction ?? this.armorReduction,
      effectType: effectType ?? this.effectType,
      rawEffectType: rawEffectType ?? this.rawEffectType,
      effectValue: effectValue ?? this.effectValue,
      scalingFormula: scalingFormula ?? this.scalingFormula,
      activationTrigger: activationTrigger ?? this.activationTrigger,
      targetScope: targetScope ?? this.targetScope,
      loreDescription: loreDescription ?? this.loreDescription,
      cardArtAssetId: cardArtAssetId ?? this.cardArtAssetId,
    );
  }

  factory BuildingCardEntity.fromCsv(Map<String, String> row) {
    final rawEffect = (row['passive_effect_type'] ?? '').trim().toUpperCase();
    final effectType = _parseEffectType(rawEffect);
    final affinity = _parseAffinity((row['axie_class_affinity'] ?? '').trim());

    return BuildingCardEntity(
      id: (row['structure_id'] ?? '').trim(),
      name: (row['name'] ?? '').trim(),
      axieClassAffinity: affinity,
      manaCost: int.tryParse((row['mana_cost'] ?? '').trim()) ?? 1,
      maxHp: int.tryParse((row['base_hp'] ?? '').trim()) ?? 10,
      armorReduction: int.tryParse((row['armor_reduction'] ?? '').trim()) ?? 0,
      effectType: effectType,
      rawEffectType: rawEffect,
      effectValue: int.tryParse((row['effect_value'] ?? '').trim()) ?? 0,
      scalingFormula: (row['scaling_formula'] ?? 'NONE').trim(),
      activationTrigger: (row['activation_trigger'] ?? 'PASSIVE').trim(),
      targetScope: (row['target_scope'] ?? 'LANE_UNIT').trim(),
      loreDescription: (row['lore_description'] ?? '').trim(),
      cardArtAssetId: (row['card_art_asset_id'] ?? '').trim(),
    );
  }

  static BuildingEffectType _parseEffectType(String raw) {
    switch (raw) {
      case 'BUFF_ATK':
        return BuildingEffectType.attackAura;
      case 'BUFF_DEF':
        return BuildingEffectType.defenseAura;
      case 'HEAL_TRIGGER':
        return BuildingEffectType.roundStartRepair;
      case 'DAMAGE_TRIGGER':
        return BuildingEffectType.damageTrigger;
      case 'SWAP_STATS':
        return BuildingEffectType.swapStats;
      case 'UTILITY':
      default:
        return BuildingEffectType.utility;
    }
  }

  static BoardClassAffinity _parseAffinity(String raw) {
    switch (raw.toLowerCase()) {
      case 'beast':
        return BoardClassAffinity.beast;
      case 'aquatic':
      case 'aqua':
        return BoardClassAffinity.aquatic;
      case 'plant':
        return BoardClassAffinity.plant;
      case 'bird':
        return BoardClassAffinity.bird;
      case 'bug':
        return BoardClassAffinity.bug;
      case 'reptile':
        return BoardClassAffinity.reptile;
      case 'neutral':
      default:
        return BoardClassAffinity.neutral;
    }
  }

  factory BuildingCardEntity.attackTotem({String? id}) {
    return BuildingCardEntity(
      id: id ?? 'bldg_atk_totem',
      name: 'Attack Totem',
      axieClassAffinity: BoardClassAffinity.beast,
      manaCost: 2,
      maxHp: 12,
      armorReduction: 1,
      effectType: BuildingEffectType.attackAura,
      rawEffectType: 'BUFF_ATK',
      effectValue: 2,
      cardArtAssetId: 'asset_struct_outpost_of_vigor',
    );
  }

  factory BuildingCardEntity.defenseBarricade({String? id}) {
    return BuildingCardEntity(
      id: id ?? 'bldg_def_barricade',
      name: 'Defense Barricade',
      axieClassAffinity: BoardClassAffinity.plant,
      manaCost: 2,
      maxHp: 16,
      armorReduction: 2,
      effectType: BuildingEffectType.defenseAura,
      rawEffectType: 'BUFF_DEF',
      effectValue: 5,
      cardArtAssetId: 'asset_struct_forest_shrine',
    );
  }

  factory BuildingCardEntity.vitalityShrine({String? id}) {
    return BuildingCardEntity(
      id: id ?? 'bldg_vitality_shrine',
      name: 'Vitality Shrine',
      axieClassAffinity: BoardClassAffinity.plant,
      manaCost: 3,
      maxHp: 14,
      armorReduction: 1,
      effectType: BuildingEffectType.roundStartRepair,
      rawEffectType: 'HEAL_TRIGGER',
      effectValue: 8,
      cardArtAssetId: 'asset_struct_lunalog_bastion',
    );
  }
}
