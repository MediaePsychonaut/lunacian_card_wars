// ===============================================================================
// [MODULE_NAME]: axie_card_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: In-memory Axie Card Model deserializing axpInfo level & Master Spec stats with Floop abilities.
// [DEPENDENCIES]: combat/combat_enums.dart, combat/combat_card.dart, combat/floop_ability_entity.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import 'combat/combat_enums.dart';
import 'combat/combat_card.dart';
import 'combat/floop_ability_entity.dart';

enum AxieElementalClass { beast, aquatic, plant, bird, bug, reptile, mech, dusk, dawn, unknown }
enum FloopSource { mouth, tail }

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
  });

  int get atk => baseAtk;
  int get def => baseDef;
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
    );
  }

  factory AxieCardEntity.fromLocalJson(Map<String, dynamic> json) => AxieCardEntity.fromGraphQL(json);

  factory AxieCardEntity.fromGraphQL(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '0';

    // Extract on-chain AXP level from verified axpInfo field, falling back to level or 1 if unranked
    final axpInfo = json['axpInfo'] as Map<String, dynamic>?;
    final level = (axpInfo?['level'] as num?)?.toInt() ?? (json['level'] as num?)?.toInt() ?? 1;

    final className = (json['class'] as String?)?.toLowerCase() ?? 'unknown';

    AxieElementalClass resolvedClass;
    switch (className) {
      case 'beast': resolvedClass = AxieElementalClass.beast; break;
      case 'aquatic': resolvedClass = AxieElementalClass.aquatic; break;
      case 'plant': resolvedClass = AxieElementalClass.plant; break;
      case 'bird': resolvedClass = AxieElementalClass.bird; break;
      case 'bug': resolvedClass = AxieElementalClass.bug; break;
      case 'reptile': resolvedClass = AxieElementalClass.reptile; break;
      case 'mech': resolvedClass = AxieElementalClass.mech; break;
      case 'dusk': resolvedClass = AxieElementalClass.dusk; break;
      case 'dawn': resolvedClass = AxieElementalClass.dawn; break;
      default: resolvedClass = AxieElementalClass.unknown;
    }

    // Master Spec v3.1 Mana Formula: min(7, floor(level / 10) + 1)
    final calculatedMana = (level ~/ 10) + 1;
    final manaCost = calculatedMana > 7 ? 7 : (calculatedMana < 1 ? 1 : calculatedMana);

    final parts = (json['parts'] as List<dynamic>?) ?? [];
    String mouthName = 'Basic Bite';
    String tailName = 'Basic Tail';
    String hornName = 'Standard Horn';
    String backName = 'Standard Shell';

    for (final p in parts) {
      if (p is Map<String, dynamic>) {
        final type = p['type']?.toString().toLowerCase();
        final pName = p['name']?.toString() ?? '';
        if (type == 'mouth') mouthName = pName;
        if (type == 'tail') tailName = pName;
        if (type == 'horn') hornName = pName;
        if (type == 'back') backName = pName;
      }
    }

    final baseAtk = 8 + (hornName.length % 12);
    final baseDef = 10 + (backName.length % 15);
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
      baseAtk: baseAtk,
      baseDef: baseDef,
      initialPips: initialPips,
      maxPips: 3,
      mouthPartName: mouthName,
      tailPartName: tailName,
      selectedFloop: FloopSource.mouth,
      spriteUrl: resolvedSprite,
      proxySpriteUrl: proxyUrl,
      rawGenes: json,
    );
  }
}
