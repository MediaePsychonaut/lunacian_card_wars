// ===============================================================================
// [MODULE_NAME]: board_unit_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Represents an Axie unit currently deployed on the board with Floop ability
// [DEPENDENCIES]: axie_card_entity.dart, floop_ability_entity.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import '../axie_card_entity.dart';
import 'floop_ability_entity.dart';

class BoardUnitEntity {
  final String instanceId;
  final String axieId;
  final String name;
  final AxieElementalClass axieClass;
  final int currentAtk;
  final int currentDef;
  final int maxDef;
  final int currentPips;
  final int maxPips;
  final bool hasFlooped;
  final FloopSource selectedFloop;
  final String spriteUrl;
  final String proxySpriteUrl;
  final FloopAbilityEntity? floop;

  const BoardUnitEntity({
    required this.instanceId,
    required this.axieId,
    required this.name,
    required this.axieClass,
    required this.currentAtk,
    required this.currentDef,
    required this.maxDef,
    required this.currentPips,
    required this.maxPips,
    required this.hasFlooped,
    required this.selectedFloop,
    required this.spriteUrl,
    required this.proxySpriteUrl,
    this.floop,
  });

  int get baseAtk => currentAtk;
  int get baseDef => maxDef;

  BoardUnitEntity copyWith({
    String? instanceId,
    String? axieId,
    String? name,
    AxieElementalClass? axieClass,
    int? currentAtk,
    int? baseAtk,
    int? currentDef,
    int? maxDef,
    int? baseDef,
    int? currentPips,
    int? maxPips,
    bool? hasFlooped,
    FloopSource? selectedFloop,
    String? spriteUrl,
    String? proxySpriteUrl,
    FloopAbilityEntity? floop,
    bool clearFloop = false,
  }) {
    return BoardUnitEntity(
      instanceId: instanceId ?? this.instanceId,
      axieId: axieId ?? this.axieId,
      name: name ?? this.name,
      axieClass: axieClass ?? this.axieClass,
      currentAtk: currentAtk ?? baseAtk ?? this.currentAtk,
      currentDef: currentDef ?? this.currentDef,
      maxDef: maxDef ?? baseDef ?? this.maxDef,
      currentPips: currentPips ?? this.currentPips,
      maxPips: maxPips ?? this.maxPips,
      hasFlooped: hasFlooped ?? this.hasFlooped,
      selectedFloop: selectedFloop ?? this.selectedFloop,
      spriteUrl: spriteUrl ?? this.spriteUrl,
      proxySpriteUrl: proxySpriteUrl ?? this.proxySpriteUrl,
      floop: clearFloop ? null : (floop ?? this.floop),
    );
  }

  factory BoardUnitEntity.fromAxieCard(AxieCardEntity card, {required String instanceId}) {
    return BoardUnitEntity(
      instanceId: instanceId,
      axieId: card.id,
      name: card.name,
      axieClass: card.axieClass,
      currentAtk: card.atk,
      currentDef: card.def,
      maxDef: card.def,
      currentPips: card.initialPips,
      maxPips: card.maxPips,
      hasFlooped: false,
      selectedFloop: card.selectedFloop,
      spriteUrl: card.spriteUrl,
      proxySpriteUrl: card.proxySpriteUrl,
      floop: card.floop,
    );
  }
}
