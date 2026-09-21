// ===============================================================================
// [MODULE_NAME]: floop_ability_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: First-class entity modeling activated Floop abilities for Axie creatures with dynamic scaling, stat modulation biases, and secret combinations.
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
  final int atkMod;
  final int defMod;
  final String scalingFormula;
  final String conditionalRule;
  final bool isSecret;

  const FloopAbilityEntity({
    required this.id,
    required this.name,
    required this.manaCost,
    required this.description,
    required this.targetRequirement,
    required this.effectType,
    required this.effectValue,
    this.atkMod = 0,
    this.defMod = 0,
    this.scalingFormula = 'NONE',
    this.conditionalRule = 'NONE',
    this.isSecret = false,
  });

  /// Resolves final scaled effect value based on occupying Axie creature mana cost:
  /// V_final = V_base + Delta * (AxieMana - 1)
  int resolveScaledValue(int axieManaCost) {
    if (scalingFormula == 'NONE' || axieManaCost <= 1) {
      return effectValue;
    }

    final regex = RegExp(r'\*\s*(\d+)');
    final match = regex.firstMatch(scalingFormula);
    if (match != null) {
      final delta = int.tryParse(match.group(1) ?? '0') ?? 0;
      return effectValue + delta * (axieManaCost - 1);
    }

    return effectValue;
  }

  FloopAbilityEntity copyWith({
    String? id,
    String? name,
    int? manaCost,
    String? description,
    FloopTargetType? targetRequirement,
    FloopEffectType? effectType,
    int? effectValue,
    int? atkMod,
    int? defMod,
    String? scalingFormula,
    String? conditionalRule,
    bool? isSecret,
  }) {
    return FloopAbilityEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      manaCost: manaCost ?? this.manaCost,
      description: description ?? this.description,
      targetRequirement: targetRequirement ?? this.targetRequirement,
      effectType: effectType ?? this.effectType,
      effectValue: effectValue ?? this.effectValue,
      atkMod: atkMod ?? this.atkMod,
      defMod: defMod ?? this.defMod,
      scalingFormula: scalingFormula ?? this.scalingFormula,
      conditionalRule: conditionalRule ?? this.conditionalRule,
      isSecret: isSecret ?? this.isSecret,
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
        atkMod,
        defMod,
        scalingFormula,
        conditionalRule,
        isSecret,
      ];
}
