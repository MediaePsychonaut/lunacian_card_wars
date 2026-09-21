// ===============================================================================
// [MODULE_NAME]: axie_card_factory.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Services
// [INTENT]: Factory service providing canonical starters, archetype creatures, and standard 20-card combat decks
// [DEPENDENCIES]: ../entities/axie_card_entity.dart, ../entities/combat/floop_ability_entity.dart, ../entities/combat/building_card_entity.dart, ../entities/combat/spell_card_entity.dart, ../entities/combat/combat_card.dart
// [ARCHITECTURE]: Pure Domain Factory Pattern
// ===============================================================================

import '../entities/axie_card_entity.dart';
import '../entities/combat/floop_ability_entity.dart';
import '../entities/combat/building_card_entity.dart';
import '../entities/combat/spell_card_entity.dart';
import '../entities/combat/combat_card.dart';

class AxieCardFactory {
  // Canonical Starters
  static AxieCardEntity bubaStarter({String? instanceId}) {
    return AxieCardEntity(
      id: instanceId ?? 'axie_buba',
      name: 'Buba',
      axieClass: AxieElementalClass.beast,
      level: 25,
      manaCost: 3,
      baseAtk: 16,
      baseDef: 11,
      initialPips: 1,
      maxPips: 3,
      mouthPartName: 'Buba Fangs',
      tailPartName: 'Buba Brush',
      selectedFloop: FloopSource.mouth,
      spriteUrl: 'https://assets.axieinfinity.com/axies/buba/axie/axie-full-transparent.png',
      proxySpriteUrl: 'https://wsrv.nl/?url=buba',
      rawGenes: const {'class': 'beast', 'name': 'Buba'},
      floop: const FloopAbilityEntity(
        id: 'floop_buba_claw',
        name: 'Brutal Claw',
        manaCost: 1,
        description: 'Deals 5 direct damage to opposing lane unit or building/hero.',
        targetRequirement: FloopTargetType.laneEnemyUnit,
        effectType: FloopEffectType.directDamage,
        effectValue: 5,
      ),
    );
  }

  static AxieCardEntity olekStarter({String? instanceId}) {
    return AxieCardEntity(
      id: instanceId ?? 'axie_olek',
      name: 'Olek',
      axieClass: AxieElementalClass.plant,
      level: 25,
      manaCost: 3,
      baseAtk: 9,
      baseDef: 18,
      initialPips: 0,
      maxPips: 3,
      mouthPartName: 'Olek Bite',
      tailPartName: 'Olek Root',
      selectedFloop: FloopSource.mouth,
      spriteUrl: 'https://assets.axieinfinity.com/axies/olek/axie/axie-full-transparent.png',
      proxySpriteUrl: 'https://wsrv.nl/?url=olek',
      rawGenes: const {'class': 'plant', 'name': 'Olek'},
      floop: const FloopAbilityEntity(
        id: 'floop_olek_armor',
        name: 'Forest Armor',
        manaCost: 1,
        description: 'Restores 6 DEF to self (capped at base DEF).',
        targetRequirement: FloopTargetType.self,
        effectType: FloopEffectType.restoreDef,
        effectValue: 6,
      ),
    );
  }

  static AxieCardEntity puffyStarter({String? instanceId}) {
    return AxieCardEntity(
      id: instanceId ?? 'axie_puffy',
      name: 'Puffy',
      axieClass: AxieElementalClass.aquatic,
      level: 25,
      manaCost: 3,
      baseAtk: 14,
      baseDef: 13,
      initialPips: 0,
      maxPips: 3,
      mouthPartName: 'Puffy Fin',
      tailPartName: 'Puffy Tail',
      selectedFloop: FloopSource.mouth,
      spriteUrl: 'https://assets.axieinfinity.com/axies/puffy/axie/axie-full-transparent.png',
      proxySpriteUrl: 'https://wsrv.nl/?url=puffy',
      rawGenes: const {'class': 'aquatic', 'name': 'Puffy'},
      floop: const FloopAbilityEntity(
        id: 'floop_puffy_surge',
        name: 'Bubble Surge',
        manaCost: 2,
        description: 'Grants +4 ATK to self.',
        targetRequirement: FloopTargetType.self,
        effectType: FloopEffectType.buffAtk,
        effectValue: 4,
      ),
    );
  }

  // Canonical Archetypes
  static AxieCardEntity littleOwl({String? instanceId}) {
    return AxieCardEntity(
      id: instanceId ?? 'axie_little_owl',
      name: 'Little Owl',
      axieClass: AxieElementalClass.bird,
      level: 20,
      manaCost: 2,
      baseAtk: 12,
      baseDef: 6,
      initialPips: 0,
      maxPips: 3,
      mouthPartName: 'Owl Beak',
      tailPartName: 'Owl Feather',
      selectedFloop: FloopSource.mouth,
      spriteUrl: 'https://assets.axieinfinity.com/axies/owl/axie/axie-full-transparent.png',
      proxySpriteUrl: 'https://wsrv.nl/?url=owl',
      rawGenes: const {'class': 'bird', 'name': 'Little Owl'},
      floop: const FloopAbilityEntity(
        id: 'floop_owl_strike',
        name: 'Feather Strike',
        manaCost: 1,
        description: 'Deals 4 direct damage to opposing lane unit or building/hero.',
        targetRequirement: FloopTargetType.laneEnemyUnit,
        effectType: FloopEffectType.directDamage,
        effectValue: 4,
      ),
    );
  }

  static AxieCardEntity pockyBug({String? instanceId}) {
    return AxieCardEntity(
      id: instanceId ?? 'axie_pocky_bug',
      name: 'Pocky Bug',
      axieClass: AxieElementalClass.bug,
      level: 20,
      manaCost: 2,
      baseAtk: 8,
      baseDef: 10,
      initialPips: 1,
      maxPips: 3,
      mouthPartName: 'Pocky Mandibles',
      tailPartName: 'Pocky Antenna',
      selectedFloop: FloopSource.mouth,
      spriteUrl: 'https://assets.axieinfinity.com/axies/bug/axie/axie-full-transparent.png',
      proxySpriteUrl: 'https://wsrv.nl/?url=bug',
      rawGenes: const {'class': 'bug', 'name': 'Pocky Bug'},
      floop: const FloopAbilityEntity(
        id: 'floop_pocky_spore',
        name: 'Numbing Spore',
        manaCost: 1,
        description: 'Reduces opposing unit ATK by 3.',
        targetRequirement: FloopTargetType.laneEnemyUnit,
        effectType: FloopEffectType.debuffEnemyAtk,
        effectValue: 3,
      ),
    );
  }

  static AxieCardEntity triSpikes({String? instanceId}) {
    return AxieCardEntity(
      id: instanceId ?? 'axie_tri_spikes',
      name: 'Tri Spikes',
      axieClass: AxieElementalClass.reptile,
      level: 25,
      manaCost: 3,
      baseAtk: 9,
      baseDef: 18,
      initialPips: 0,
      maxPips: 3,
      mouthPartName: 'Tri Scaly',
      tailPartName: 'Tri Tail',
      selectedFloop: FloopSource.mouth,
      spriteUrl: 'https://assets.axieinfinity.com/axies/reptile/axie/axie-full-transparent.png',
      proxySpriteUrl: 'https://wsrv.nl/?url=reptile',
      rawGenes: const {'class': 'reptile', 'name': 'Tri Spikes'},
      floop: const FloopAbilityEntity(
        id: 'floop_tri_shield',
        name: 'Spike Shield',
        manaCost: 2,
        description: 'Restores 8 DEF to self (capped at base DEF).',
        targetRequirement: FloopTargetType.self,
        effectType: FloopEffectType.restoreDef,
        effectValue: 8,
      ),
    );
  }

  // Canonical 20-Card Deck
  static List<CombatCard> createCanonicalDeck(String playerPrefix) {
    return [
      // 12 Axies (2 of each)
      bubaStarter(instanceId: '${playerPrefix}_buba_1'),
      bubaStarter(instanceId: '${playerPrefix}_buba_2'),
      olekStarter(instanceId: '${playerPrefix}_olek_1'),
      olekStarter(instanceId: '${playerPrefix}_olek_2'),
      puffyStarter(instanceId: '${playerPrefix}_puffy_1'),
      puffyStarter(instanceId: '${playerPrefix}_puffy_2'),
      littleOwl(instanceId: '${playerPrefix}_owl_1'),
      littleOwl(instanceId: '${playerPrefix}_owl_2'),
      pockyBug(instanceId: '${playerPrefix}_bug_1'),
      pockyBug(instanceId: '${playerPrefix}_bug_2'),
      triSpikes(instanceId: '${playerPrefix}_tri_1'),
      triSpikes(instanceId: '${playerPrefix}_tri_2'),

      // 4 Tactical Buildings
      BuildingCardEntity.attackTotem(id: '${playerPrefix}_bldg_atk_1'),
      BuildingCardEntity.defenseBarricade(id: '${playerPrefix}_bldg_def_1'),
      BuildingCardEntity.vitalityShrine(id: '${playerPrefix}_bldg_rep_1'),
      BuildingCardEntity.attackTotem(id: '${playerPrefix}_bldg_atk_2'),

      // 4 Tactical Spells
      SpellCardEntity.potionOfVitality(id: '${playerPrefix}_spell_pot_1'),
      SpellCardEntity.potionOfVitality(id: '${playerPrefix}_spell_pot_2'),
      SpellCardEntity.starShuriken(id: '${playerPrefix}_spell_shuriken_1'),
      SpellCardEntity.lunarBlessing(id: '${playerPrefix}_spell_lunar_1'),
    ];
  }
}
