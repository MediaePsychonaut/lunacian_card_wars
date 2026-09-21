// ===============================================================================
// [MODULE_NAME]: floop_catalog_repository.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Data / Repositories
// [INTENT]: Ingestion repository parsing axie_part_floops_matrix.csv and resolving authentic Floop abilities for all Axie parts.
// [DEPENDENCIES]: package:flutter/services.dart, dart:io, package:flutter_riverpod/flutter_riverpod.dart, ../../domain/entities/combat/floop_ability_entity.dart, ../../domain/entities/axie_card_entity.dart
// [ARCHITECTURE]: Clean Architecture Repository Pattern
// ===============================================================================

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/axie_card_entity.dart';
import '../../domain/entities/combat/floop_ability_entity.dart';

abstract class IFloopCatalogRepository {
  Future<List<FloopAbilityEntity>> loadFloopMatrix();
  FloopAbilityEntity getFloopForPart({
    required String partName,
    required String partType,
    AxieElementalClass? axieClass,
  });
}

class FloopCatalogRepository implements IFloopCatalogRepository {
  static const String floopsCsvPath = 'assets/data/generated/axie_part_floops_matrix.csv';

  List<FloopAbilityEntity>? _cachedFloops;
  final Map<String, FloopAbilityEntity> _partNameToFloop = {};

  FloopCatalogRepository() {
    _initializeSynchronousCache();
  }

  @override
  Future<List<FloopAbilityEntity>> loadFloopMatrix() async {
    if (_cachedFloops != null && _cachedFloops!.isNotEmpty) {
      return _cachedFloops!;
    }

    final csvContent = await _loadAssetOrFile(floopsCsvPath);
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return _cachedFloops ?? [];

    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final floops = <FloopAbilityEntity>[];

    for (final line in lines.sublist(1)) {
      final cols = _parseCsvLine(line);
      if (cols.length != headers.length) continue;

      final row = <String, String>{};
      for (int i = 0; i < headers.length; i++) {
        row[headers[i]] = cols[i].trim();
      }

      final floop = _floopFromRow(row);
      floops.add(floop);

      final pName = row['part_name']?.toLowerCase() ?? '';
      if (pName.isNotEmpty) {
        _partNameToFloop[pName] = floop;
        _partNameToFloop[_normalizeKey(pName)] = floop;
      }
    }

    _cachedFloops = floops;
    return floops;
  }

  @override
  FloopAbilityEntity getFloopForPart({
    required String partName,
    required String partType,
    AxieElementalClass? axieClass,
  }) {
    final cleanName = partName.trim().toLowerCase();
    final normName = _normalizeKey(cleanName);

    // 1. Direct or normalized cache match
    if (_partNameToFloop.containsKey(cleanName)) {
      return _partNameToFloop[cleanName]!;
    }
    if (_partNameToFloop.containsKey(normName)) {
      return _partNameToFloop[normName]!;
    }

    // 2. Partial substring search in cached keys
    for (final entry in _partNameToFloop.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return entry.value;
      }
    }

    // 3. Archetype fallback according to slot & class
    return _createClassSlotFallback(partName, partType, axieClass);
  }

  static String _normalizeKey(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static FloopAbilityEntity _floopFromRow(Map<String, String> row) {
    final floopId = row['floop_id'] ?? 'flp_generic';
    final floopName = row['floop_name'] ?? 'Generic Floop';
    final mana = int.tryParse(row['activation_mana_cost'] ?? '1') ?? 1;
    final atkShift = int.tryParse(row['atk_bias_shift'] ?? '0') ?? 0;
    final defShift = int.tryParse(row['def_bias_shift'] ?? '0') ?? 0;
    final effectTypeRaw = (row['effect_type'] ?? 'DAMAGE').toUpperCase();
    final baseVal = int.tryParse(row['base_value'] ?? '0') ?? 0;
    final formula = row['scaling_formula'] ?? 'NONE';
    final cond = row['conditional_rule'] ?? 'NONE';
    final targetRaw = (row['target_scope'] ?? 'OPPOSING_LANE').toUpperCase();
    final isSec = (row['is_secret'] ?? '0') == '1';

    FloopTargetType target = FloopTargetType.laneEnemyUnit;
    if (targetRaw == 'SELF') {
      target = FloopTargetType.self;
    } else if (targetRaw == 'OPPOSING_HERO') {
      target = FloopTargetType.opposingHero;
    } else if (targetRaw == 'ALLIED_LANE') {
      target = FloopTargetType.alliedLaneUnit;
    }

    FloopEffectType effect = FloopEffectType.directDamage;
    if (effectTypeRaw == 'BUFF_ATK' || effectTypeRaw == 'BUFF_SPEED') {
      effect = FloopEffectType.buffAtk;
    } else if (effectTypeRaw == 'HEAL' || effectTypeRaw == 'SHIELD' || effectTypeRaw == 'THORNS_BUFF') {
      effect = FloopEffectType.restoreDef;
    } else if (effectTypeRaw == 'DEBUFF_ATK') {
      effect = FloopEffectType.debuffEnemyAtk;
    }

    final desc = _generateFloopDescription(
      effectTypeRaw: effectTypeRaw,
      baseVal: baseVal,
      targetRaw: targetRaw,
      formula: formula,
      cond: cond,
    );

    return FloopAbilityEntity(
      id: floopId,
      name: floopName,
      manaCost: mana,
      description: desc,
      targetRequirement: target,
      effectType: effect,
      effectValue: baseVal,
      atkMod: atkShift,
      defMod: defShift,
      scalingFormula: formula,
      conditionalRule: cond,
      isSecret: isSec,
    );
  }

  static String _generateFloopDescription({
    required String effectTypeRaw,
    required int baseVal,
    required String targetRaw,
    required String formula,
    required String cond,
  }) {
    String desc;
    switch (effectTypeRaw) {
      case 'DAMAGE':
        desc = 'Deals $baseVal direct damage to opposing lane unit.';
        break;
      case 'BURST_DAMAGE':
        desc = 'Deals $baseVal burst damage directly to target.';
        break;
      case 'BUFF_ATK':
        desc = 'Grants +$baseVal ATK to self.';
        break;
      case 'BUFF_SPEED':
        desc = 'Grants +$baseVal speed and priority in clash.';
        break;
      case 'HEAL':
        desc = 'Restores +$baseVal DEF to allied target.';
        break;
      case 'SHIELD':
        desc = 'Grants +$baseVal DEF shield to self.';
        break;
      case 'DEBUFF_ATK':
        desc = 'Reduces opposing unit ATK by -$baseVal.';
        break;
      case 'STEAL_MANA':
        desc = 'Steals $baseVal Mana from opposing player.';
        break;
      case 'GAIN_MANA':
        desc = 'Gains +$baseVal bonus Mana for active turn.';
        break;
      case 'DISCARD':
        desc = 'Forces opponent to discard $baseVal card(s).';
        break;
      case 'POISON':
        desc = 'Inflicts $baseVal Poison stacks on opposing lane.';
        break;
      case 'STUN':
        desc = 'Stuns enemy unit, preventing action for 1 turn.';
        break;
      case 'SLEEP':
        desc = 'Puts opposing enemy to Sleep for 1 turn.';
        break;
      case 'FEAR':
        desc = 'Inflicts Fear on enemy, disabling attacks.';
        break;
      case 'SWAP_LANE':
        desc = 'Swaps position with adjacent allied lane.';
        break;
      case 'DRAW':
        desc = 'Draws $baseVal card(s) from your deck.';
        break;
      case 'BOUNCE':
        desc = 'Bounces target enemy unit back to opponent hand.';
        break;
      case 'DISABLE_FLOP':
        desc = 'Disables target opposing unit Floop ability.';
        break;
      case 'THORNS_BUFF':
        desc = 'Grants Thorns reflecting damage back to attacker.';
        break;
      default:
        desc = 'Activates specialized Floop tactical effect ($baseVal pts).';
    }

    if (formula.contains('*')) {
      final regex = RegExp(r'\*\s*(\d+)');
      final match = regex.firstMatch(formula);
      if (match != null) {
        final delta = match.group(1);
        desc += ' (+$delta per Axie Mana > 1)';
      }
    }

    return desc;
  }

  FloopAbilityEntity _createClassSlotFallback(String partName, String partType, AxieElementalClass? axieClass) {
    final c = axieClass ?? AxieElementalClass.beast;
    final isMouth = partType.toLowerCase() == 'mouth';

    if (isMouth) {
      return FloopAbilityEntity(
        id: 'flp_${c.name}_mouth_fallback',
        name: '$partName Strike',
        manaCost: 1,
        description: 'Deals 12 direct damage to opposing lane unit.',
        targetRequirement: FloopTargetType.laneEnemyUnit,
        effectType: FloopEffectType.directDamage,
        effectValue: 12,
        atkMod: 5,
        defMod: -5,
      );
    } else {
      return FloopAbilityEntity(
        id: 'flp_${c.name}_tail_fallback',
        name: '$partName Sweep',
        manaCost: 1,
        description: 'Restores +10 DEF shield to self.',
        targetRequirement: FloopTargetType.self,
        effectType: FloopEffectType.restoreDef,
        effectValue: 10,
        atkMod: -5,
        defMod: 5,
      );
    }
  }

  void _initializeSynchronousCache() {
    // 73 Master Floop matrix entries from axie_part_floops_matrix.csv pre-seeded
    final rawEntries = [
      // Beast Mouths
      {'part_name': 'Nutcracker', 'floop_id': 'flp_b_mouth_01', 'floop_name': 'Nutcracker Bite', 'activation_mana_cost': '1', 'atk_bias_shift': '5', 'def_bias_shift': '-5', 'effect_type': 'DAMAGE', 'base_value': '15', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 10', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Axie Kiss', 'floop_id': 'flp_b_mouth_02', 'floop_name': 'Death Kiss', 'activation_mana_cost': '2', 'atk_bias_shift': '10', 'def_bias_shift': '-10', 'effect_type': 'BUFF_ATK', 'base_value': '12', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 8', 'target_scope': 'SELF'},
      {'part_name': 'Goda', 'floop_id': 'flp_b_mouth_03', 'floop_name': 'Piercing Howl', 'activation_mana_cost': '1', 'atk_bias_shift': '5', 'def_bias_shift': '-5', 'effect_type': 'DISCARD', 'base_value': '10', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Confident', 'floop_id': 'flp_b_mouth_04', 'floop_name': 'Self Assurance', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'BUFF_ATK', 'base_value': '8', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 5', 'target_scope': 'SELF'},
      // Aqua Mouths
      {'part_name': 'Lam', 'floop_id': 'flp_aq_mouth_01', 'floop_name': 'Angry Lam', 'activation_mana_cost': '1', 'atk_bias_shift': '5', 'def_bias_shift': '-5', 'effect_type': 'DAMAGE', 'base_value': '14', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 8', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Risky Fish', 'floop_id': 'flp_aq_mouth_02', 'floop_name': 'Fish Hook', 'activation_mana_cost': '2', 'atk_bias_shift': '10', 'def_bias_shift': '-10', 'effect_type': 'DAMAGE', 'base_value': '22', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 12', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Piranha', 'floop_id': 'flp_aq_mouth_03', 'floop_name': 'Crimson Water', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'DAMAGE', 'base_value': '10', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Catfish', 'floop_id': 'flp_aq_mouth_04', 'floop_name': 'Swallow Whole', 'activation_mana_cost': '2', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'HEAL', 'base_value': '18', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 10', 'target_scope': 'SELF'},
      // Plant Mouths
      {'part_name': 'Serious', 'floop_id': 'flp_pl_mouth_01', 'floop_name': 'Vegetal Bite', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'STEAL_MANA', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Zigzag', 'floop_id': 'flp_pl_mouth_02', 'floop_name': 'Drain Bite', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'HEAL', 'base_value': '12', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 6', 'target_scope': 'SELF'},
      {'part_name': 'Herbivore', 'floop_id': 'flp_pl_mouth_03', 'floop_name': 'Vegan Diet', 'activation_mana_cost': '2', 'atk_bias_shift': '-10', 'def_bias_shift': '10', 'effect_type': 'SHIELD', 'base_value': '25', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 15', 'target_scope': 'SELF'},
      {'part_name': 'Silence Whisper', 'floop_id': 'flp_pl_mouth_04', 'floop_name': 'Forest Breath', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'HEAL', 'base_value': '15', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 8', 'target_scope': 'ALLIED_LANE'},
      // Bird Mouths
      {'part_name': 'Doubletalk', 'floop_id': 'flp_bd_mouth_01', 'floop_name': 'Soothing Song', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'SLEEP', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Peace Maker', 'floop_id': 'flp_bd_mouth_02', 'floop_name': 'Peace Treaty', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'DEBUFF_ATK', 'base_value': '8', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 5', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Little Owl', 'floop_id': 'flp_bd_mouth_03', 'floop_name': 'Dark Swoop', 'activation_mana_cost': '2', 'atk_bias_shift': '15', 'def_bias_shift': '-15', 'effect_type': 'BURST_DAMAGE', 'base_value': '28', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 15', 'target_scope': 'OPPOSING_HERO'},
      {'part_name': 'Hungry Bird', 'floop_id': 'flp_bd_mouth_04', 'floop_name': 'Insectivore', 'activation_mana_cost': '1', 'atk_bias_shift': '5', 'def_bias_shift': '-5', 'effect_type': 'DAMAGE', 'base_value': '12', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 6', 'target_scope': 'OPPOSING_LANE'},
      // Bug Mouths
      {'part_name': 'Mosquito', 'floop_id': 'flp_bg_mouth_01', 'floop_name': 'Blood Taste', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'HEAL', 'base_value': '10', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 5', 'target_scope': 'SELF'},
      {'part_name': 'Cute Bunny', 'floop_id': 'flp_bg_mouth_02', 'floop_name': 'Terror Chomp', 'activation_mana_cost': '2', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'FEAR', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Square Teeth', 'floop_id': 'flp_bg_mouth_03', 'floop_name': 'Nut Cracking', 'activation_mana_cost': '1', 'atk_bias_shift': '10', 'def_bias_shift': '-10', 'effect_type': 'DAMAGE', 'base_value': '16', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 8', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Pincer', 'floop_id': 'flp_bg_mouth_04', 'floop_name': 'Surgical Pincer', 'activation_mana_cost': '1', 'atk_bias_shift': '5', 'def_bias_shift': '-5', 'effect_type': 'DISCARD', 'base_value': '12', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 6', 'target_scope': 'ANY_LANE_ENEMY'},
      // Reptile Mouths
      {'part_name': 'Toothless Bite', 'floop_id': 'flp_rp_mouth_01', 'floop_name': 'Sneaky Raid', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'DEBUFF_ATK', 'base_value': '10', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 6', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Kotaro', 'floop_id': 'flp_rp_mouth_02', 'floop_name': 'Kotaro Bite', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'GAIN_MANA', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'SELF'},
      {'part_name': 'Razor Bite', 'floop_id': 'flp_rp_mouth_03', 'floop_name': 'Venom Fang', 'activation_mana_cost': '2', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'POISON', 'base_value': '2', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 1', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Tiny Turtle', 'floop_id': 'flp_rp_mouth_04', 'floop_name': 'Chomp', 'activation_mana_cost': '2', 'atk_bias_shift': '-10', 'def_bias_shift': '10', 'effect_type': 'STUN', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      // Beast Tails
      {'part_name': 'Cottontail', 'floop_id': 'flp_b_tail_01', 'floop_name': 'Luna Absorb', 'activation_mana_cost': '0', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'GAIN_MANA', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'SELF'},
      {'part_name': 'Rice', 'floop_id': 'flp_b_tail_02', 'floop_name': 'Night Rice', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'STEAL_MANA', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Shiba', 'floop_id': 'flp_b_tail_03', 'floop_name': 'Shiba Strike', 'activation_mana_cost': '2', 'atk_bias_shift': '15', 'def_bias_shift': '-15', 'effect_type': 'DAMAGE', 'base_value': '25', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 12', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Gerbil', 'floop_id': 'flp_b_tail_04', 'floop_name': 'Gerbil Jump', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'SWAP_LANE', 'base_value': '0', 'scaling_formula': 'NONE', 'target_scope': 'SELF'},
      {'part_name': 'Hare', 'floop_id': 'flp_b_tail_05', 'floop_name': 'Hare Rush', 'activation_mana_cost': '1', 'atk_bias_shift': '5', 'def_bias_shift': '-5', 'effect_type': 'DRAW', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'SELF'},
      // Aqua Tails
      {'part_name': 'Koi', 'floop_id': 'flp_aq_tail_01', 'floop_name': 'Upstream Swift', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'BUFF_SPEED', 'base_value': '10', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 5', 'target_scope': 'SELF'},
      {'part_name': 'Nimo', 'floop_id': 'flp_aq_tail_02', 'floop_name': 'Tail Slap', 'activation_mana_cost': '0', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'GAIN_MANA', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'SELF'},
      {'part_name': 'Tadpole', 'floop_id': 'flp_aq_tail_03', 'floop_name': 'Black Bubble', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'DEBUFF_ATK', 'base_value': '6', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 4', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Ranchu', 'floop_id': 'flp_aq_tail_04', 'floop_name': 'Water Spout', 'activation_mana_cost': '2', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'DEBUFF_ATK', 'base_value': '15', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 8', 'target_scope': 'ANY_LANE_ENEMY'},
      {'part_name': 'Navaga', 'floop_id': 'flp_aq_tail_05', 'floop_name': 'Ice Spear', 'activation_mana_cost': '1', 'atk_bias_shift': '5', 'def_bias_shift': '-5', 'effect_type': 'DAMAGE', 'base_value': '12', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 6', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Shrimp', 'floop_id': 'flp_aq_tail_06', 'floop_name': 'Chitin Jump', 'activation_mana_cost': '2', 'atk_bias_shift': '10', 'def_bias_shift': '-10', 'effect_type': 'BURST_DAMAGE', 'base_value': '24', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 12', 'target_scope': 'OPPOSING_HERO'},
      // Plant Tails
      {'part_name': 'Carrot', 'floop_id': 'flp_pl_tail_01', 'floop_name': 'Carrot Hammer', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'SHIELD', 'base_value': '20', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 10', 'target_scope': 'SELF'},
      {'part_name': 'Cattail', 'floop_id': 'flp_pl_tail_02', 'floop_name': 'Cattail Slap', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'DRAW', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'SELF'},
      {'part_name': 'Hatsune', 'floop_id': 'flp_pl_tail_03', 'floop_name': 'Forest Glow', 'activation_mana_cost': '2', 'atk_bias_shift': '-10', 'def_bias_shift': '10', 'effect_type': 'SHIELD', 'base_value': '28', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 14', 'target_scope': 'SELF'},
      {'part_name': 'Yam', 'floop_id': 'flp_pl_tail_04', 'floop_name': 'Gas Unleash', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'POISON', 'base_value': '2', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 1', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Potato Leaf', 'floop_id': 'flp_pl_tail_05', 'floop_name': 'Aqua Defense', 'activation_mana_cost': '1', 'atk_bias_shift': '-10', 'def_bias_shift': '10', 'effect_type': 'SHIELD', 'base_value': '22', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 10', 'target_scope': 'SELF'},
      {'part_name': 'Hot Butt', 'floop_id': 'flp_pl_tail_06', 'floop_name': 'Spicy Surprise', 'activation_mana_cost': '2', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'DAMAGE', 'base_value': '18', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 8', 'target_scope': 'OPPOSING_LANE'},
      // Bird Tails
      {'part_name': 'Swallow', 'floop_id': 'flp_bd_tail_01', 'floop_name': 'Early Storm', 'activation_mana_cost': '1', 'atk_bias_shift': '5', 'def_bias_shift': '-5', 'effect_type': 'DAMAGE', 'base_value': '14', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 7', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Feather Fan', 'floop_id': 'flp_bd_tail_02', 'floop_name': 'Triple Feather', 'activation_mana_cost': '2', 'atk_bias_shift': '10', 'def_bias_shift': '-10', 'effect_type': 'DAMAGE', 'base_value': '26', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 14', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'The Last One', 'floop_id': 'flp_bd_tail_03', 'floop_name': 'Risky Feather', 'activation_mana_cost': '2', 'atk_bias_shift': '15', 'def_bias_shift': '-15', 'effect_type': 'BURST_DAMAGE', 'base_value': '30', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 15', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Cloud', 'floop_id': 'flp_bd_tail_04', 'floop_name': 'Puffy Feather', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'SWAP_LANE', 'base_value': '0', 'scaling_formula': 'NONE', 'target_scope': 'SELF'},
      {'part_name': "Granma's Fan", 'floop_id': 'flp_bd_tail_05', 'floop_name': 'Cool Breeze', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'DEBUFF_ATK', 'base_value': '8', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 4', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Post Fight', 'floop_id': 'flp_bd_tail_06', 'floop_name': 'All-out Shot', 'activation_mana_cost': '2', 'atk_bias_shift': '20', 'def_bias_shift': '-20', 'effect_type': 'BURST_DAMAGE', 'base_value': '35', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 18', 'target_scope': 'OPPOSING_HERO'},
      // Bug Tails
      {'part_name': 'Ant', 'floop_id': 'flp_bg_tail_01', 'floop_name': 'Chemical Warfare', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'DISCARD', 'base_value': '8', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 4', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Twin Needle', 'floop_id': 'flp_bg_tail_02', 'floop_name': 'Double Stab', 'activation_mana_cost': '2', 'atk_bias_shift': '10', 'def_bias_shift': '-10', 'effect_type': 'DAMAGE', 'base_value': '24', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 12', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Fish Snack', 'floop_id': 'flp_bg_tail_03', 'floop_name': 'Anesthetic Bait', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'STUN', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Gravel Ant', 'floop_id': 'flp_bg_tail_04', 'floop_name': 'Sand Trap', 'activation_mana_cost': '2', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'DISABLE_FLOP', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Pupae', 'floop_id': 'flp_bg_tail_05', 'floop_name': 'Metamorphosis', 'activation_mana_cost': '1', 'atk_bias_shift': '-10', 'def_bias_shift': '10', 'effect_type': 'SHIELD', 'base_value': '20', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 10', 'target_scope': 'SELF'},
      {'part_name': 'Thorny Caterpillar', 'floop_id': 'flp_bg_tail_06', 'floop_name': 'Allergic React', 'activation_mana_cost': '2', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'DAMAGE', 'base_value': '22', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 10', 'target_scope': 'OPPOSING_LANE'},
      // Reptile Tails
      {'part_name': 'Wall Gecko', 'floop_id': 'flp_rp_tail_01', 'floop_name': 'Critical Escape', 'activation_mana_cost': '1', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'SHIELD', 'base_value': '18', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 8', 'target_scope': 'SELF'},
      {'part_name': 'Iguana', 'floop_id': 'flp_rp_tail_02', 'floop_name': 'Scale Dart', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'STEAL_MANA', 'base_value': '1', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Tiny Dino', 'floop_id': 'flp_rp_tail_03', 'floop_name': 'Tiny Stomp', 'activation_mana_cost': '2', 'atk_bias_shift': '5', 'def_bias_shift': '-5', 'effect_type': 'DAMAGE', 'base_value': '20', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 10', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Snake Jar', 'floop_id': 'flp_rp_tail_04', 'floop_name': 'Jar Armor', 'activation_mana_cost': '2', 'atk_bias_shift': '-10', 'def_bias_shift': '10', 'effect_type': 'SHIELD', 'base_value': '26', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 12', 'target_scope': 'SELF'},
      {'part_name': 'Gila', 'floop_id': 'flp_rp_tail_05', 'floop_name': 'Neurotoxin', 'activation_mana_cost': '2', 'atk_bias_shift': '-5', 'def_bias_shift': '5', 'effect_type': 'POISON', 'base_value': '3', 'scaling_formula': 'BASE + (AXIE_MANA - 1) * 1', 'target_scope': 'OPPOSING_LANE'},
      {'part_name': 'Grass Snake', 'floop_id': 'flp_rp_tail_06', 'floop_name': 'Venom Spray', 'activation_mana_cost': '1', 'atk_bias_shift': '0', 'def_bias_shift': '0', 'effect_type': 'POISON', 'base_value': '2', 'scaling_formula': 'NONE', 'target_scope': 'OPPOSING_LANE'},
    ];

    for (final entry in rawEntries) {
      final floop = _floopFromRow(entry);
      final pName = entry['part_name']!.toLowerCase();
      _partNameToFloop[pName] = floop;
      _partNameToFloop[_normalizeKey(pName)] = floop;
    }
  }

  Future<String> _loadAssetOrFile(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return file.readAsStringSync();
        }
      } catch (_) {}
      return '';
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}

final floopCatalogRepositoryProvider = Provider<IFloopCatalogRepository>((ref) {
  return FloopCatalogRepository();
});

final floopCatalogMatrixProvider = FutureProvider<List<FloopAbilityEntity>>((ref) async {
  final repo = ref.watch(floopCatalogRepositoryProvider);
  return await repo.loadFloopMatrix();
});
