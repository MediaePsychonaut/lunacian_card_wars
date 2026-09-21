// ===============================================================================
// [MODULE_NAME]: axie_card_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: In-memory Axie Card Model deserializing axpInfo level & Master Spec stats with Floop abilities and stat conservation bias shifts.
// [DEPENDENCIES]: combat/combat_enums.dart, combat/combat_card.dart, combat/floop_ability_entity.dart, ../services/axie_stat_calibrator.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'combat/combat_enums.dart';
import 'combat/combat_card.dart';
import 'combat/floop_ability_entity.dart';
import '../services/axie_stat_calibrator.dart';

enum AxieElementalClass { beast, aquatic, plant, bird, bug, reptile, mech, dusk, dawn, unknown }
enum FloopSource { mouth, tail, secret }

class AxieCardEntity implements CombatCard {
  @override
  final String id;
  @override
  final String name;
  final AxieElementalClass axieClass;
  final int level;
  @override
  final int manaCost;
  final int baseAtk;
  final int baseDef;
  final int initialPips;
  final int maxPips;
  final String mouthPartName;
  final String tailPartName;
  final FloopSource selectedFloop;
  final String spriteUrl;
  final String proxySpriteUrl;
  final Map<String, dynamic> rawGenes;
  final FloopAbilityEntity? floop;
  final AxieElementalClass? hornClass;
  final AxieElementalClass? backClass;
  final int numEvolvedParts;

  const AxieCardEntity({
    required this.id,
    required this.name,
    required this.axieClass,
    required this.level,
    required this.manaCost,
    required this.baseAtk,
    required this.baseDef,
    required this.initialPips,
    required this.maxPips,
    required this.mouthPartName,
    required this.tailPartName,
    required this.selectedFloop,
    required this.spriteUrl,
    required this.proxySpriteUrl,
    required this.rawGenes,
    this.floop,
    this.hornClass,
    this.backClass,
    this.numEvolvedParts = 0,
  });

  int get effectiveAtk => baseAtk + (floop?.atkMod ?? 0);
  int get effectiveDef => baseDef + (floop?.defMod ?? 0);

  int get atk => effectiveAtk;
  int get def => effectiveDef;
  String get imageUrl => spriteUrl;
  String get className => axieClass.name.toUpperCase();

  BoardClassAffinity get affinity => switch (axieClass) {
    AxieElementalClass.beast => BoardClassAffinity.beast,
    AxieElementalClass.aquatic => BoardClassAffinity.aquatic,
    AxieElementalClass.plant => BoardClassAffinity.plant,
    AxieElementalClass.bird => BoardClassAffinity.bird,
    AxieElementalClass.bug => BoardClassAffinity.bug,
    AxieElementalClass.reptile => BoardClassAffinity.reptile,
    _ => BoardClassAffinity.neutral,
  };

  /// Recalculates base ATK and DEF for a new mana cost using deterministic BST calibration.
  AxieCardEntity recalculateForManaCost(int newManaCost, {int? numEvolvedParts}) {
    final evolved = numEvolvedParts ?? this.numEvolvedParts;
    int hp = 0, speed = 0, skill = 0, morale = 0;
    final stats = rawGenes['stats'] as Map<String, dynamic>?;
    if (stats != null) {
      hp = (stats['hp'] as num?)?.toInt() ?? 0;
      speed = (stats['speed'] as num?)?.toInt() ?? 0;
      skill = (stats['skill'] as num?)?.toInt() ?? 0;
      morale = (stats['morale'] as num?)?.toInt() ?? 0;
    }

    final calibrated = AxieStatCalibrator.calibrate(
      manaCost: newManaCost,
      bodyClass: axieClass,
      hornClass: hornClass,
      backClass: backClass,
      numEvolvedParts: evolved,
      isMouthFloop: selectedFloop == FloopSource.mouth,
      hp: hp,
      speed: speed,
      skill: skill,
      morale: morale,
    );

    return copyWith(
      manaCost: newManaCost,
      baseAtk: calibrated.atk,
      baseDef: calibrated.def,
      numEvolvedParts: evolved,
    );
  }

  AxieCardEntity copyWith({
    String? id,
    String? name,
    AxieElementalClass? axieClass,
    int? level,
    int? manaCost,
    int? baseAtk,
    int? baseDef,
    int? initialPips,
    int? maxPips,
    String? mouthPartName,
    String? tailPartName,
    FloopSource? selectedFloop,
    String? spriteUrl,
    String? proxySpriteUrl,
    Map<String, dynamic>? rawGenes,
    FloopAbilityEntity? floop,
    bool clearFloop = false,
    AxieElementalClass? hornClass,
    AxieElementalClass? backClass,
    int? numEvolvedParts,
  }) {
    return AxieCardEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      axieClass: axieClass ?? this.axieClass,
      level: level ?? this.level,
      manaCost: manaCost ?? this.manaCost,
      baseAtk: baseAtk ?? this.baseAtk,
      baseDef: baseDef ?? this.baseDef,
      initialPips: initialPips ?? this.initialPips,
      maxPips: maxPips ?? this.maxPips,
      mouthPartName: mouthPartName ?? this.mouthPartName,
      tailPartName: tailPartName ?? this.tailPartName,
      selectedFloop: selectedFloop ?? this.selectedFloop,
      spriteUrl: spriteUrl ?? this.spriteUrl,
      proxySpriteUrl: proxySpriteUrl ?? this.proxySpriteUrl,
      rawGenes: rawGenes ?? this.rawGenes,
      floop: clearFloop ? null : (floop ?? this.floop),
      hornClass: hornClass ?? this.hornClass,
      backClass: backClass ?? this.backClass,
      numEvolvedParts: numEvolvedParts ?? this.numEvolvedParts,
    );
  }

  factory AxieCardEntity.fromLocalJson(Map<String, dynamic> json) => AxieCardEntity.fromGraphQL(json);

  factory AxieCardEntity.fromGraphQL(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '0';

    // Extract on-chain AXP level from verified axpInfo field, falling back to level or 1 if unranked
    final axpInfo = json['axpInfo'] as Map<String, dynamic>?;
    final level = (axpInfo?['level'] as num?)?.toInt() ?? (json['level'] as num?)?.toInt() ?? 1;

    final className = (json['class'] as String?)?.toLowerCase() ?? 'unknown';

    final resolvedClass = AxieStatCalibrator.parseClass(className);

    // Master Spec v3.1 Mana Formula: min(7, floor(level / 10) + 1)
    final calculatedMana = (level ~/ 10) + 1;
    final manaCost = calculatedMana > 7 ? 7 : (calculatedMana < 1 ? 1 : calculatedMana);

    final parts = (json['parts'] as List<dynamic>?) ?? [];
    String mouthName = 'Basic Bite';
    String tailName = 'Basic Tail';
    AxieElementalClass? hornClass;
    AxieElementalClass? backClass;
    int evolvedCount = 0;

    for (final p in parts) {
      if (p is Map<String, dynamic>) {
        final type = p['type']?.toString().toLowerCase();
        final pName = p['name']?.toString() ?? '';
        final pClassStr = p['class']?.toString();
        final pClass = pClassStr != null ? AxieStatCalibrator.parseClass(pClassStr) : null;
        final stage = (p['stage'] as num?)?.toInt() ?? 1;
        if (stage >= 2) evolvedCount++;

        if (type == 'mouth') mouthName = pName;
        if (type == 'tail') tailName = pName;
        if (type == 'horn') {
          hornClass = pClass;
        }
        if (type == 'back') {
          backClass = pClass;
        }
      }
    }

    final stats = json['stats'] as Map<String, dynamic>?;
    final hp = (stats?['hp'] as num?)?.toInt() ?? 0;
    final speed = (stats?['speed'] as num?)?.toInt() ?? 0;
    final skill = (stats?['skill'] as num?)?.toInt() ?? 0;
    final morale = (stats?['morale'] as num?)?.toInt() ?? 0;

    final numEvolvedParts = (json['numEvolvedParts'] as num?)?.toInt() ?? evolvedCount;

    final calibrated = AxieStatCalibrator.calibrate(
      manaCost: manaCost,
      bodyClass: resolvedClass,
      hornClass: hornClass,
      backClass: backClass,
      numEvolvedParts: numEvolvedParts,
      isMouthFloop: true,
      hp: hp,
      speed: speed,
      skill: skill,
      morale: morale,
    );

    final initialPips = (resolvedClass == AxieElementalClass.beast || resolvedClass == AxieElementalClass.bug) ? 1 : 0;

    // Direct root image resolution with verified CDN transparent fallback & wsrv.nl proxy URL
    final rawImage = json['image'] as String?;
    final defaultUrl = 'https://assets.axieinfinity.com/axies/$id/axie/axie-full-transparent.png';
    final resolvedSprite = (rawImage != null && rawImage.isNotEmpty) ? rawImage : defaultUrl;
    final proxyUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(resolvedSprite)}';

    return AxieCardEntity(
      id: id,
      name: json['name']?.toString() ?? 'Axie #$id',
      axieClass: resolvedClass,
      level: level,
      manaCost: manaCost,
      baseAtk: calibrated.atk,
      baseDef: calibrated.def,
      initialPips: initialPips,
      maxPips: 3,
      mouthPartName: mouthName,
      tailPartName: tailName,
      selectedFloop: FloopSource.mouth,
      spriteUrl: resolvedSprite,
      proxySpriteUrl: proxyUrl,
      rawGenes: json,
      hornClass: hornClass,
      backClass: backClass,
      numEvolvedParts: numEvolvedParts,
    );
  }
}
