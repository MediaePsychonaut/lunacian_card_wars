// ===============================================================================
// [MODULE_NAME]: spell_card_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Tactical one-shot spell cards implementing CombatCard with Lunacian class affinities and effect schemas.
// [DEPENDENCIES]: combat_card.dart, combat_enums.dart, equatable.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'combat_card.dart';
import 'combat_enums.dart';
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
  final BoardClassAffinity axieClassAffinity;
  @override
  final int manaCost;
  final String spellType;
  final SpellTargetType targetType;
  final SpellEffectType effectType;
  final String rawEffectType;
  final int effectValue;
  final String scalingFormula;
  final String targetScope;
  final String castWindow;
  final String rarity;
  final String description;
  final String cardArtAssetId;

  const SpellCardEntity({
    required this.id,
    required this.name,
    this.axieClassAffinity = BoardClassAffinity.neutral,
    required this.manaCost,
    this.spellType = 'TARGETED',
    required this.targetType,
    required this.effectType,
    this.rawEffectType = '',
    required this.effectValue,
    this.scalingFormula = 'NONE',
    this.targetScope = 'SINGLE_CREATURE',
    this.castWindow = 'ACTION_PHASE',
    this.rarity = 'COMMON',
    required this.description,
    this.cardArtAssetId = '',
  });

  SpellCardEntity copyWith({
    String? id,
    String? name,
    BoardClassAffinity? axieClassAffinity,
    int? manaCost,
    String? spellType,
    SpellTargetType? targetType,
    SpellEffectType? effectType,
    String? rawEffectType,
    int? effectValue,
    String? scalingFormula,
    String? targetScope,
    String? castWindow,
    String? rarity,
    String? description,
    String? cardArtAssetId,
  }) {
    return SpellCardEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      axieClassAffinity: axieClassAffinity ?? this.axieClassAffinity,
      manaCost: manaCost ?? this.manaCost,
      spellType: spellType ?? this.spellType,
      targetType: targetType ?? this.targetType,
      effectType: effectType ?? this.effectType,
      rawEffectType: rawEffectType ?? this.rawEffectType,
      effectValue: effectValue ?? this.effectValue,
      scalingFormula: scalingFormula ?? this.scalingFormula,
      targetScope: targetScope ?? this.targetScope,
      castWindow: castWindow ?? this.castWindow,
      rarity: rarity ?? this.rarity,
      description: description ?? this.description,
      cardArtAssetId: cardArtAssetId ?? this.cardArtAssetId,
    );
  }

  factory SpellCardEntity.fromCsv(Map<String, String> row) {
    final rawEffect = (row['effect_type'] ?? '').trim().toUpperCase();
    final rawTarget = (row['target_scope'] ?? '').trim().toUpperCase();
    final affinity = _parseAffinity((row['axie_class_affinity'] ?? '').trim());

    return SpellCardEntity(
      id: (row['spell_id'] ?? '').trim(),
      name: (row['name'] ?? '').trim(),
      axieClassAffinity: affinity,
      manaCost: int.tryParse((row['mana_cost'] ?? '').trim()) ?? 1,
      spellType: (row['spell_type'] ?? 'TARGETED').trim(),
      targetType: _parseTargetType(rawTarget, rawEffect),
      effectType: _parseEffectType(rawEffect),
      rawEffectType: rawEffect,
      effectValue: int.tryParse((row['base_value'] ?? '').trim()) ?? 0,
      scalingFormula: (row['scaling_formula'] ?? 'NONE').trim(),
      targetScope: rawTarget.isEmpty ? 'SINGLE_CREATURE' : rawTarget,
      castWindow: (row['cast_window'] ?? 'ACTION_PHASE').trim(),
      rarity: (row['rarity'] ?? 'COMMON').trim(),
      description: (row['description'] ?? '').trim(),
      cardArtAssetId: (row['card_art_asset_id'] ?? '').trim(),
    );
  }

  static SpellTargetType _parseTargetType(String targetScope, String effectType) {
    switch (targetScope) {
      case 'HERO':
        return SpellTargetType.enemyHero;
      case 'LANE':
        return SpellTargetType.laneSlot;
      case 'ALL_CREATURES':
      case 'PLAYER':
      case 'SINGLE_CREATURE':
      default:
        if (effectType == 'DAMAGE' || effectType == 'DESTROY') {
          return SpellTargetType.enemyUnit;
        }
        return SpellTargetType.alliedUnit;
    }
  }

  static SpellEffectType _parseEffectType(String raw) {
    switch (raw) {
      case 'DAMAGE':
        return SpellEffectType.directDamage;
      case 'HEAL':
      case 'GRANT_DEF':
        return SpellEffectType.grantDef;
      case 'BUFF_ATK':
      case 'GRANT_ATK':
        return SpellEffectType.grantAtk;
      case 'REPAIR':
      case 'REPAIR_BUILDING':
        return SpellEffectType.repairBuilding;
      default:
        return SpellEffectType.directDamage;
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

  factory SpellCardEntity.potionOfVitality({String id = 'spell_vitality_potion'}) {
    return SpellCardEntity(
      id: id,
      name: 'Potion of Vitality',
      axieClassAffinity: BoardClassAffinity.neutral,
      manaCost: 1,
      spellType: 'TARGETED',
      targetType: SpellTargetType.alliedUnit,
      effectType: SpellEffectType.grantDef,
      rawEffectType: 'HEAL',
      effectValue: 6,
      targetScope: 'SINGLE_CREATURE',
      castWindow: 'ACTION_PHASE',
      rarity: 'COMMON',
      description: 'Grants +6 DEF (capped at maxDef) to allied unit.',
      cardArtAssetId: 'asset_spell_nectar_of_life',
    );
  }

  factory SpellCardEntity.starShuriken({String id = 'spell_star_shuriken'}) {
    return SpellCardEntity(
      id: id,
      name: 'Star Shuriken',
      axieClassAffinity: BoardClassAffinity.neutral,
      manaCost: 2,
      spellType: 'TARGETED',
      targetType: SpellTargetType.enemyUnit,
      effectType: SpellEffectType.directDamage,
      rawEffectType: 'DAMAGE',
      effectValue: 5,
      targetScope: 'SINGLE_CREATURE',
      castWindow: 'ACTION_PHASE',
      rarity: 'COMMON',
      description: 'Deals 5 direct unmitigated damage to enemy unit.',
      cardArtAssetId: 'asset_spell_feathered_strike',
    );
  }

  factory SpellCardEntity.lunarBlessing({String id = 'spell_lunar_blessing'}) {
    return SpellCardEntity(
      id: id,
      name: 'Lunar Blessing',
      axieClassAffinity: BoardClassAffinity.neutral,
      manaCost: 2,
      spellType: 'TARGETED',
      targetType: SpellTargetType.alliedUnit,
      effectType: SpellEffectType.grantAtk,
      rawEffectType: 'BUFF_ATK',
      effectValue: 3,
      targetScope: 'SINGLE_CREATURE',
      castWindow: 'ACTION_PHASE',
      rarity: 'RARE',
      description: 'Grants +3 persistent ATK to allied unit.',
      cardArtAssetId: 'asset_spell_yggdrasil_blessing',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        axieClassAffinity,
        manaCost,
        spellType,
        targetType,
        effectType,
        rawEffectType,
        effectValue,
        scalingFormula,
        targetScope,
        castWindow,
        rarity,
        description,
        cardArtAssetId,
      ];
}
