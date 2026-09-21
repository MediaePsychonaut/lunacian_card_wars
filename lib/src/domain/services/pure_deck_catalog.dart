// ===============================================================================
// [MODULE_NAME]: pure_deck_catalog.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Services
// [INTENT]: Factory service providing the 6 canonical Pure Elemental Decks (Beast, Aquatic, Plant, Bird, Bug, Reptile) with 25 cards each (15 calibrated Axies, 5 structures from master catalog, 5 spells from master catalog) and 4 matching pure landscape tiles.
// [DEPENDENCIES]: ../entities/deck_entity.dart, ../entities/axie_card_entity.dart, ../entities/combat/combat_card.dart, ../entities/combat/combat_enums.dart, ../entities/combat/floop_ability_entity.dart, ../entities/combat/building_card_entity.dart, ../entities/combat/spell_card_entity.dart, ../../data/repositories/floop_catalog_repository.dart
// [ARCHITECTURE]: Pure Domain Factory Pattern
// ===============================================================================

import '../../data/repositories/floop_catalog_repository.dart';
import '../entities/axie_card_entity.dart';
import '../entities/combat/building_card_entity.dart';
import '../entities/combat/combat_card.dart';
import '../entities/combat/combat_enums.dart';
import '../entities/combat/floop_ability_entity.dart';
import '../entities/combat/spell_card_entity.dart';
import '../entities/deck_entity.dart';

class PureDeckCatalog {
  static final FloopCatalogRepository _floopRepo = FloopCatalogRepository();

  /// Returns all 6 pre-loaded pure elemental decks
  static List<DeckEntity> get allPureDecks => [
        beastPureDeck(),
        aquaticPureDeck(),
        plantPureDeck(),
        birdPureDeck(),
        bugPureDeck(),
        reptilePureDeck(),
      ];

  static DeckEntity getDeckByClass(AxieElementalClass axieClass) {
    switch (axieClass) {
      case AxieElementalClass.beast:
        return beastPureDeck();
      case AxieElementalClass.aquatic:
        return aquaticPureDeck();
      case AxieElementalClass.plant:
        return plantPureDeck();
      case AxieElementalClass.bird:
        return birdPureDeck();
      case AxieElementalClass.bug:
        return bugPureDeck();
      case AxieElementalClass.reptile:
        return reptilePureDeck();
      default:
        return beastPureDeck();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. PURE BEAST DECK (Hay / Corn Aggro - 25 Cards)
  // ─────────────────────────────────────────────────────────────────────────────
  static DeckEntity beastPureDeck({String prefix = 'pure_beast'}) {
    final fNut = _floopRepo.getFloopForPart(partName: 'Nutcracker', partType: 'mouth', axieClass: AxieElementalClass.beast);
    final fKiss = _floopRepo.getFloopForPart(partName: 'Axie Kiss', partType: 'mouth', axieClass: AxieElementalClass.beast);
    final fGoda = _floopRepo.getFloopForPart(partName: 'Goda', partType: 'mouth', axieClass: AxieElementalClass.beast);
    final fConf = _floopRepo.getFloopForPart(partName: 'Confident', partType: 'mouth', axieClass: AxieElementalClass.beast);
    final fShiba = _floopRepo.getFloopForPart(partName: 'Shiba', partType: 'tail', axieClass: AxieElementalClass.beast);
    final fHare = _floopRepo.getFloopForPart(partName: 'Hare', partType: 'tail', axieClass: AxieElementalClass.beast);
    final fRice = _floopRepo.getFloopForPart(partName: 'Rice', partType: 'tail', axieClass: AxieElementalClass.beast);
    final fCotton = _floopRepo.getFloopForPart(partName: 'Cottontail', partType: 'tail', axieClass: AxieElementalClass.beast);

    final cards = <CombatCard>[
      // 15 Beast Axies (7 pairs + 1 single = 15 cards, max 2 copies per floop)
      _createAxie('${prefix}_nutcracker_1', 'Buba Nutcracker', AxieElementalClass.beast, 3, 17, 10, 'Nutcracker', 'Cottontail', FloopSource.mouth, fNut),
      _createAxie('${prefix}_nutcracker_2', 'Buba Nutcracker', AxieElementalClass.beast, 3, 17, 10, 'Nutcracker', 'Cottontail', FloopSource.mouth, fNut),
      _createAxie('${prefix}_kiss_1', 'Kissing Beast', AxieElementalClass.beast, 2, 12, 6, 'Axie Kiss', 'Gerbil', FloopSource.mouth, fKiss),
      _createAxie('${prefix}_kiss_2', 'Kissing Beast', AxieElementalClass.beast, 2, 12, 6, 'Axie Kiss', 'Gerbil', FloopSource.mouth, fKiss),
      _createAxie('${prefix}_goda_1', 'Howling Goda', AxieElementalClass.beast, 2, 10, 8, 'Goda', 'Cottontail', FloopSource.mouth, fGoda),
      _createAxie('${prefix}_goda_2', 'Howling Goda', AxieElementalClass.beast, 2, 10, 8, 'Goda', 'Cottontail', FloopSource.mouth, fGoda),
      _createAxie('${prefix}_confident_1', 'Brave Confident', AxieElementalClass.beast, 1, 6, 4, 'Confident', 'Hare', FloopSource.mouth, fConf),
      _createAxie('${prefix}_confident_2', 'Brave Confident', AxieElementalClass.beast, 1, 6, 4, 'Confident', 'Hare', FloopSource.mouth, fConf),
      _createAxie('${prefix}_shiba_1', 'Shiba Hunter', AxieElementalClass.beast, 3, 19, 8, 'Confident', 'Shiba', FloopSource.tail, fShiba),
      _createAxie('${prefix}_shiba_2', 'Shiba Hunter', AxieElementalClass.beast, 3, 19, 8, 'Confident', 'Shiba', FloopSource.tail, fShiba),
      _createAxie('${prefix}_hare_1', 'Hare Striker', AxieElementalClass.beast, 2, 11, 7, 'Confident', 'Hare', FloopSource.tail, fHare),
      _createAxie('${prefix}_hare_2', 'Hare Striker', AxieElementalClass.beast, 2, 11, 7, 'Confident', 'Hare', FloopSource.tail, fHare),
      _createAxie('${prefix}_rice_1', 'Night Rice', AxieElementalClass.beast, 2, 9, 9, 'Confident', 'Rice', FloopSource.tail, fRice),
      _createAxie('${prefix}_rice_2', 'Night Rice', AxieElementalClass.beast, 2, 9, 9, 'Confident', 'Rice', FloopSource.tail, fRice),
      _createAxie('${prefix}_cottontail_1', 'Luna Cottontail', AxieElementalClass.beast, 1, 5, 5, 'Nutcracker', 'Cottontail', FloopSource.tail, fCotton),

      // 5 Structures from structures_master.csv (str_07, str_08, str_26)
      _createStructure(
        id: '${prefix}_bden_1',
        name: 'Beast Den Stronghold',
        manaCost: 3,
        maxHp: 20,
        armorReduction: 2,
        effectType: BuildingEffectType.attackAura,
        rawEffectType: 'BUFF_ATK',
        effectValue: 2,
        loreDescription: 'Creature in this lane gets +2 Attack for each allied unit on field.',
        cardArtAssetId: 'asset_struct_beast_den_stronghold',
      ),
      _createStructure(
        id: '${prefix}_bden_2',
        name: 'Beast Den Stronghold',
        manaCost: 3,
        maxHp: 20,
        armorReduction: 2,
        effectType: BuildingEffectType.attackAura,
        rawEffectType: 'BUFF_ATK',
        effectValue: 2,
        loreDescription: 'Creature in this lane gets +2 Attack for each allied unit on field.',
        cardArtAssetId: 'asset_struct_beast_den_stronghold',
      ),
      _createStructure(
        id: '${prefix}_parena_1',
        name: 'Primal Arena',
        manaCost: 2,
        maxHp: 12,
        armorReduction: 0,
        effectType: BuildingEffectType.attackAura,
        rawEffectType: 'BUFF_ATK',
        effectValue: 3,
        loreDescription: 'Creature in this lane gets +3 Attack.',
        cardArtAssetId: 'asset_struct_primal_arena',
      ),
      _createStructure(
        id: '${prefix}_parena_2',
        name: 'Primal Arena',
        manaCost: 2,
        maxHp: 12,
        armorReduction: 0,
        effectType: BuildingEffectType.attackAura,
        rawEffectType: 'BUFF_ATK',
        effectValue: 3,
        loreDescription: 'Creature in this lane gets +3 Attack.',
        cardArtAssetId: 'asset_struct_primal_arena',
      ),
      _createStructure(
        id: '${prefix}_crimson_1',
        name: 'Crimson Barricade',
        manaCost: 2,
        maxHp: 16,
        armorReduction: 1,
        rawEffectType: 'DAMAGE_TRIGGER',
        effectValue: 5,
        activationTrigger: 'ON_SUMMON',
        targetScope: 'HERO',
        loreDescription: 'Deal 5 damage to opposing hero when a new unit is deployed in this lane.',
        cardArtAssetId: 'asset_struct_crimson_barricade',
      ),

      // 5 Spells from spells_master.csv (spl_10, spl_04, spl_34)
      _createSpell(
        id: '${prefix}_pscepter_1',
        name: 'Primal Scepter',
        manaCost: 1,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        description: 'Choose a Beast ally to strike opposing lane unit immediately.',
        cardArtAssetId: 'asset_spell_primal_scepter',
      ),
      _createSpell(
        id: '${prefix}_pscepter_2',
        name: 'Primal Scepter',
        manaCost: 1,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        description: 'Choose a Beast ally to strike opposing lane unit immediately.',
        cardArtAssetId: 'asset_spell_primal_scepter',
      ),
      _createSpell(
        id: '${prefix}_bloodlust_1',
        name: 'Bloodlust Transfusion',
        manaCost: 2,
        rawEffectType: 'DAMAGE',
        effectValue: 5,
        targetScope: 'HERO',
        description: 'Deal 5 damage to opposing hero and restore 5 HP to your hero.',
        cardArtAssetId: 'asset_spell_bloodlust_transfusion',
      ),
      _createSpell(
        id: '${prefix}_bloodlust_2',
        name: 'Bloodlust Transfusion',
        manaCost: 2,
        rawEffectType: 'DAMAGE',
        effectValue: 5,
        targetScope: 'HERO',
        description: 'Deal 5 damage to opposing hero and restore 5 HP to your hero.',
        cardArtAssetId: 'asset_spell_bloodlust_transfusion',
      ),
      _createSpell(
        id: '${prefix}_subjugate_1',
        name: 'Subjugating Roar',
        manaCost: 3,
        rawEffectType: 'DESTROY',
        effectValue: 1,
        targetScope: 'ALL_CREATURES',
        rarity: 'EPIC',
        description: 'Destroy all enemy creatures with Rarity 3 or lower.',
        cardArtAssetId: 'asset_spell_subjugating_roar',
      ),
    ];

    return DeckEntity(
      id: 'deck_pure_beast',
      name: 'Pure Beast (Hay Aggro)',
      cards: cards,
      landscapes: const [
        BoardClassAffinity.beast,
        BoardClassAffinity.beast,
        BoardClassAffinity.beast,
        BoardClassAffinity.beast,
      ],
      isPreset: true,
      pureClass: AxieElementalClass.beast,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. PURE AQUATIC DECK (Blue / Water Tempo - 25 Cards)
  // ─────────────────────────────────────────────────────────────────────────────
  static DeckEntity aquaticPureDeck({String prefix = 'pure_aqua'}) {
    final fLam = _floopRepo.getFloopForPart(partName: 'Lam', partType: 'mouth', axieClass: AxieElementalClass.aquatic);
    final fRisky = _floopRepo.getFloopForPart(partName: 'Risky Fish', partType: 'mouth', axieClass: AxieElementalClass.aquatic);
    final fPiranha = _floopRepo.getFloopForPart(partName: 'Piranha', partType: 'mouth', axieClass: AxieElementalClass.aquatic);
    final fCatfish = _floopRepo.getFloopForPart(partName: 'Catfish', partType: 'mouth', axieClass: AxieElementalClass.aquatic);
    final fKoi = _floopRepo.getFloopForPart(partName: 'Koi', partType: 'tail', axieClass: AxieElementalClass.aquatic);
    final fNimo = _floopRepo.getFloopForPart(partName: 'Nimo', partType: 'tail', axieClass: AxieElementalClass.aquatic);
    final fNavaga = _floopRepo.getFloopForPart(partName: 'Navaga', partType: 'tail', axieClass: AxieElementalClass.aquatic);
    final fShrimp = _floopRepo.getFloopForPart(partName: 'Shrimp', partType: 'tail', axieClass: AxieElementalClass.aquatic);

    final cards = <CombatCard>[
      // 15 Aquatic Axies (7 pairs + 1 single = 15 cards, max 2 copies per floop)
      _createAxie('${prefix}_lam_1', 'Puffy Lam', AxieElementalClass.aquatic, 3, 15, 12, 'Lam', 'Nimo', FloopSource.mouth, fLam),
      _createAxie('${prefix}_lam_2', 'Puffy Lam', AxieElementalClass.aquatic, 3, 15, 12, 'Lam', 'Nimo', FloopSource.mouth, fLam),
      _createAxie('${prefix}_risky_1', 'Risky Striker', AxieElementalClass.aquatic, 2, 13, 5, 'Risky Fish', 'Koi', FloopSource.mouth, fRisky),
      _createAxie('${prefix}_risky_2', 'Risky Striker', AxieElementalClass.aquatic, 2, 13, 5, 'Risky Fish', 'Koi', FloopSource.mouth, fRisky),
      _createAxie('${prefix}_piranha_1', 'Crimson Piranha', AxieElementalClass.aquatic, 1, 7, 3, 'Piranha', 'Navaga', FloopSource.mouth, fPiranha),
      _createAxie('${prefix}_piranha_2', 'Crimson Piranha', AxieElementalClass.aquatic, 1, 7, 3, 'Piranha', 'Navaga', FloopSource.mouth, fPiranha),
      _createAxie('${prefix}_catfish_1', 'Deep Catfish', AxieElementalClass.aquatic, 3, 12, 15, 'Catfish', 'Tadpole', FloopSource.mouth, fCatfish),
      _createAxie('${prefix}_catfish_2', 'Deep Catfish', AxieElementalClass.aquatic, 3, 12, 15, 'Catfish', 'Tadpole', FloopSource.mouth, fCatfish),
      _createAxie('${prefix}_koi_1', 'Upstream Koi', AxieElementalClass.aquatic, 2, 10, 8, 'Piranha', 'Koi', FloopSource.tail, fKoi),
      _createAxie('${prefix}_koi_2', 'Upstream Koi', AxieElementalClass.aquatic, 2, 10, 8, 'Piranha', 'Koi', FloopSource.tail, fKoi),
      _createAxie('${prefix}_nimo_1', 'Nimo Slapper', AxieElementalClass.aquatic, 2, 9, 9, 'Piranha', 'Nimo', FloopSource.tail, fNimo),
      _createAxie('${prefix}_nimo_2', 'Nimo Slapper', AxieElementalClass.aquatic, 2, 9, 9, 'Piranha', 'Nimo', FloopSource.tail, fNimo),
      _createAxie('${prefix}_navaga_1', 'Ice Navaga', AxieElementalClass.aquatic, 3, 16, 11, 'Piranha', 'Navaga', FloopSource.tail, fNavaga),
      _createAxie('${prefix}_navaga_2', 'Ice Navaga', AxieElementalClass.aquatic, 3, 16, 11, 'Piranha', 'Navaga', FloopSource.tail, fNavaga),
      _createAxie('${prefix}_shrimp_1', 'Chitin Shrimp', AxieElementalClass.aquatic, 2, 11, 7, 'Lam', 'Shrimp', FloopSource.tail, fShrimp),

      // 5 Structures from structures_master.csv (str_04, str_06, str_16)
      _createStructure(
        id: '${prefix}_coral_1',
        name: 'Coral Sanctuary',
        manaCost: 1,
        maxHp: 12,
        armorReduction: 0,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 4,
        loreDescription: 'Creature in this lane gets +2 Defense for each allied unit on field.',
        cardArtAssetId: 'asset_struct_coral_sanctuary',
      ),
      _createStructure(
        id: '${prefix}_coral_2',
        name: 'Coral Sanctuary',
        manaCost: 1,
        maxHp: 12,
        armorReduction: 0,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 4,
        loreDescription: 'Creature in this lane gets +2 Defense for each allied unit on field.',
        cardArtAssetId: 'asset_struct_coral_sanctuary',
      ),
      _createStructure(
        id: '${prefix}_tidal_1',
        name: 'Tidal Spring',
        manaCost: 2,
        maxHp: 16,
        armorReduction: 1,
        effectType: BuildingEffectType.roundStartRepair,
        rawEffectType: 'HEAL_TRIGGER',
        effectValue: 2,
        activationTrigger: 'START_OF_TURN',
        loreDescription: 'Creature in this lane heals 2 HP for each allied unit at start of turn.',
        cardArtAssetId: 'asset_struct_tidal_spring',
      ),
      _createStructure(
        id: '${prefix}_tidal_2',
        name: 'Tidal Spring',
        manaCost: 2,
        maxHp: 16,
        armorReduction: 1,
        effectType: BuildingEffectType.roundStartRepair,
        rawEffectType: 'HEAL_TRIGGER',
        effectValue: 2,
        activationTrigger: 'START_OF_TURN',
        loreDescription: 'Creature in this lane heals 2 HP for each allied unit at start of turn.',
        cardArtAssetId: 'asset_struct_tidal_spring',
      ),
      _createStructure(
        id: '${prefix}_sunken_1',
        name: 'Sunken Obelisk',
        manaCost: 2,
        maxHp: 16,
        armorReduction: 1,
        rawEffectType: 'DAMAGE_TRIGGER',
        effectValue: 4,
        activationTrigger: 'ON_DESTROY',
        targetScope: 'HERO',
        loreDescription: 'Deal 4 damage to opposing hero when allied creature in this lane is destroyed.',
        cardArtAssetId: 'asset_struct_sunken_obelisk',
      ),

      // 5 Spells from spells_master.csv (spl_27, spl_02, spl_01)
      _createSpell(
        id: '${prefix}_aquaclaw_1',
        name: 'Aquatic Wave Claws',
        manaCost: 1,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        description: 'Choose an Aquatic creature and attack opposing creature in its lane.',
        cardArtAssetId: 'asset_spell_aquatic_wave_claws',
      ),
      _createSpell(
        id: '${prefix}_aquaclaw_2',
        name: 'Aquatic Wave Claws',
        manaCost: 1,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        description: 'Choose an Aquatic creature and attack opposing creature in its lane.',
        cardArtAssetId: 'asset_spell_aquatic_wave_claws',
      ),
      _createSpell(
        id: '${prefix}_purewater_1',
        name: 'Pure Water',
        manaCost: 1,
        rawEffectType: 'DESTROY',
        effectValue: 1,
        description: 'Sacrifice an allied creature to draw 1 card.',
        cardArtAssetId: 'asset_spell_pure_water',
      ),
      _createSpell(
        id: '${prefix}_purewater_2',
        name: 'Pure Water',
        manaCost: 1,
        rawEffectType: 'DESTROY',
        effectValue: 1,
        description: 'Sacrifice an allied creature to draw 1 card.',
        cardArtAssetId: 'asset_spell_pure_water',
      ),
      _createSpell(
        id: '${prefix}_tidalsurge_1',
        name: 'Tidal Surge',
        manaCost: 4,
        rawEffectType: 'DESTROY',
        effectValue: 1,
        targetScope: 'ALL_CREATURES',
        rarity: 'RARE',
        description: 'Destroy one allied creature and one opposing creature. Draw 1 card.',
        cardArtAssetId: 'asset_spell_tidal_surge',
      ),
    ];

    return DeckEntity(
      id: 'deck_pure_aquatic',
      name: 'Pure Aquatic (Blue Tempo)',
      cards: cards,
      landscapes: const [
        BoardClassAffinity.aquatic,
        BoardClassAffinity.aquatic,
        BoardClassAffinity.aquatic,
        BoardClassAffinity.aquatic,
      ],
      isPreset: true,
      pureClass: AxieElementalClass.aquatic,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. PURE PLANT DECK (Green / Nice Sustain - 25 Cards)
  // ─────────────────────────────────────────────────────────────────────────────
  static DeckEntity plantPureDeck({String prefix = 'pure_plant'}) {
    final fSerious = _floopRepo.getFloopForPart(partName: 'Serious', partType: 'mouth', axieClass: AxieElementalClass.plant);
    final fZigzag = _floopRepo.getFloopForPart(partName: 'Zigzag', partType: 'mouth', axieClass: AxieElementalClass.plant);
    final fHerb = _floopRepo.getFloopForPart(partName: 'Herbivore', partType: 'mouth', axieClass: AxieElementalClass.plant);
    final fSilence = _floopRepo.getFloopForPart(partName: 'Silence Whisper', partType: 'mouth', axieClass: AxieElementalClass.plant);
    final fCarrot = _floopRepo.getFloopForPart(partName: 'Carrot', partType: 'tail', axieClass: AxieElementalClass.plant);
    final fCattail = _floopRepo.getFloopForPart(partName: 'Cattail', partType: 'tail', axieClass: AxieElementalClass.plant);
    final fHatsune = _floopRepo.getFloopForPart(partName: 'Hatsune', partType: 'tail', axieClass: AxieElementalClass.plant);
    final fYam = _floopRepo.getFloopForPart(partName: 'Yam', partType: 'tail', axieClass: AxieElementalClass.plant);

    final cards = <CombatCard>[
      // 15 Plant Axies (7 pairs + 1 single = 15 cards, max 2 copies per floop)
      _createAxie('${prefix}_serious_1', 'Vegetal Serious', AxieElementalClass.plant, 2, 7, 11, 'Serious', 'Carrot', FloopSource.mouth, fSerious),
      _createAxie('${prefix}_serious_2', 'Vegetal Serious', AxieElementalClass.plant, 2, 7, 11, 'Serious', 'Carrot', FloopSource.mouth, fSerious),
      _createAxie('${prefix}_zigzag_1', 'Drain Zigzag', AxieElementalClass.plant, 2, 8, 10, 'Zigzag', 'Cattail', FloopSource.mouth, fZigzag),
      _createAxie('${prefix}_zigzag_2', 'Drain Zigzag', AxieElementalClass.plant, 2, 8, 10, 'Zigzag', 'Cattail', FloopSource.mouth, fZigzag),
      _createAxie('${prefix}_herb_1', 'Vegan Herbivore', AxieElementalClass.plant, 3, 10, 17, 'Herbivore', 'Hatsune', FloopSource.mouth, fHerb),
      _createAxie('${prefix}_herb_2', 'Vegan Herbivore', AxieElementalClass.plant, 3, 10, 17, 'Herbivore', 'Hatsune', FloopSource.mouth, fHerb),
      _createAxie('${prefix}_silence_1', 'Silence Whisper', AxieElementalClass.plant, 2, 8, 10, 'Silence Whisper', 'Carrot', FloopSource.mouth, fSilence),
      _createAxie('${prefix}_silence_2', 'Silence Whisper', AxieElementalClass.plant, 2, 8, 10, 'Silence Whisper', 'Carrot', FloopSource.mouth, fSilence),
      _createAxie('${prefix}_carrot_1', 'Carrot Hammer', AxieElementalClass.plant, 3, 11, 16, 'Serious', 'Carrot', FloopSource.tail, fCarrot),
      _createAxie('${prefix}_carrot_2', 'Carrot Hammer', AxieElementalClass.plant, 3, 11, 16, 'Serious', 'Carrot', FloopSource.tail, fCarrot),
      _createAxie('${prefix}_cattail_1', 'Cattail Slapper', AxieElementalClass.plant, 2, 7, 11, 'Serious', 'Cattail', FloopSource.tail, fCattail),
      _createAxie('${prefix}_cattail_2', 'Cattail Slapper', AxieElementalClass.plant, 2, 7, 11, 'Serious', 'Cattail', FloopSource.tail, fCattail),
      _createAxie('${prefix}_hatsune_1', 'Forest Hatsune', AxieElementalClass.plant, 3, 9, 18, 'Serious', 'Hatsune', FloopSource.tail, fHatsune),
      _createAxie('${prefix}_hatsune_2', 'Forest Hatsune', AxieElementalClass.plant, 3, 9, 18, 'Serious', 'Hatsune', FloopSource.tail, fHatsune),
      _createAxie('${prefix}_yam_1', 'Yam Gas Tank', AxieElementalClass.plant, 1, 3, 7, 'Zigzag', 'Yam', FloopSource.tail, fYam),

      // 5 Structures from structures_master.csv (str_10, str_15, str_03)
      _createStructure(
        id: '${prefix}_fshrine_1',
        name: 'Forest Shrine',
        manaCost: 3,
        maxHp: 24,
        armorReduction: 2,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 9,
        loreDescription: 'Creature in this lane gets +9 Defense.',
        cardArtAssetId: 'asset_struct_forest_shrine',
      ),
      _createStructure(
        id: '${prefix}_fshrine_2',
        name: 'Forest Shrine',
        manaCost: 3,
        maxHp: 24,
        armorReduction: 2,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 9,
        loreDescription: 'Creature in this lane gets +9 Defense.',
        cardArtAssetId: 'asset_struct_forest_shrine',
      ),
      _createStructure(
        id: '${prefix}_yggtower_1',
        name: 'Yggdrasil Tower',
        manaCost: 3,
        maxHp: 20,
        armorReduction: 2,
        effectType: BuildingEffectType.roundStartRepair,
        rawEffectType: 'HEAL_TRIGGER',
        effectValue: 5,
        activationTrigger: 'START_OF_TURN',
        loreDescription: 'Creature in this lane heals 5 HP at start of turn.',
        cardArtAssetId: 'asset_struct_yggdrasil_tower',
      ),
      _createStructure(
        id: '${prefix}_yggtower_2',
        name: 'Yggdrasil Tower',
        manaCost: 3,
        maxHp: 20,
        armorReduction: 2,
        effectType: BuildingEffectType.roundStartRepair,
        rawEffectType: 'HEAL_TRIGGER',
        effectValue: 5,
        activationTrigger: 'START_OF_TURN',
        loreDescription: 'Creature in this lane heals 5 HP at start of turn.',
        cardArtAssetId: 'asset_struct_yggdrasil_tower',
      ),
      _createStructure(
        id: '${prefix}_greenhouse_1',
        name: 'Verdant Greenhouse',
        manaCost: 2,
        maxHp: 18,
        armorReduction: 1,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'SWAP_STATS',
        effectValue: 0,
        loreDescription: 'Creatures in this lane swap Attack and Defense.',
        cardArtAssetId: 'asset_struct_verdant_greenhouse',
      ),

      // 5 Spells from spells_master.csv (spl_35, spl_07, spl_33)
      _createSpell(
        id: '${prefix}_heartoak_1',
        name: 'Heart of Oak',
        manaCost: 1,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        description: 'Choose a Plant creature and attack opposing creature in its lane.',
        cardArtAssetId: 'asset_spell_heart_of_oak',
      ),
      _createSpell(
        id: '${prefix}_heartoak_2',
        name: 'Heart of Oak',
        manaCost: 1,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        description: 'Choose a Plant creature and attack opposing creature in its lane.',
        cardArtAssetId: 'asset_spell_heart_of_oak',
      ),
      _createSpell(
        id: '${prefix}_yggbless_1',
        name: 'Yggdrasil Blessing',
        manaCost: 2,
        rawEffectType: 'DRAW',
        effectValue: 3,
        targetScope: 'PLAYER',
        rarity: 'RARE',
        description: 'Draw 3 cards from your deck.',
        cardArtAssetId: 'asset_spell_yggdrasil_blessing',
      ),
      _createSpell(
        id: '${prefix}_yggbless_2',
        name: 'Yggdrasil Blessing',
        manaCost: 2,
        rawEffectType: 'DRAW',
        effectValue: 3,
        targetScope: 'PLAYER',
        rarity: 'RARE',
        description: 'Draw 3 cards from your deck.',
        cardArtAssetId: 'asset_spell_yggdrasil_blessing',
      ),
      _createSpell(
        id: '${prefix}_sprout_1',
        name: 'Sprout Growth',
        manaCost: 1,
        rawEffectType: 'DRAW',
        effectValue: 2,
        targetScope: 'PLAYER',
        description: 'Draw 2 cards from your deck.',
        cardArtAssetId: 'asset_spell_sprout_growth',
      ),
    ];

    return DeckEntity(
      id: 'deck_pure_plant',
      name: 'Pure Plant (Wood Stall)',
      cards: cards,
      landscapes: const [
        BoardClassAffinity.plant,
        BoardClassAffinity.plant,
        BoardClassAffinity.plant,
        BoardClassAffinity.plant,
      ],
      isPreset: true,
      pureClass: AxieElementalClass.plant,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. PURE BIRD DECK (Cloud / Sky Backdoor - 25 Cards)
  // ─────────────────────────────────────────────────────────────────────────────
  static DeckEntity birdPureDeck({String prefix = 'pure_bird'}) {
    final fDouble = _floopRepo.getFloopForPart(partName: 'Doubletalk', partType: 'mouth', axieClass: AxieElementalClass.bird);
    final fPeace = _floopRepo.getFloopForPart(partName: 'Peace Maker', partType: 'mouth', axieClass: AxieElementalClass.bird);
    final fOwl = _floopRepo.getFloopForPart(partName: 'Little Owl', partType: 'mouth', axieClass: AxieElementalClass.bird);
    final fHungry = _floopRepo.getFloopForPart(partName: 'Hungry Bird', partType: 'mouth', axieClass: AxieElementalClass.bird);
    final fSwallow = _floopRepo.getFloopForPart(partName: 'Swallow', partType: 'tail', axieClass: AxieElementalClass.bird);
    final fFeather = _floopRepo.getFloopForPart(partName: 'Feather Fan', partType: 'tail', axieClass: AxieElementalClass.bird);
    final fLast = _floopRepo.getFloopForPart(partName: 'The Last One', partType: 'tail', axieClass: AxieElementalClass.bird);
    final fCloud = _floopRepo.getFloopForPart(partName: 'Cloud', partType: 'tail', axieClass: AxieElementalClass.bird);

    final cards = <CombatCard>[
      // 15 Bird Axies (7 pairs + 1 single = 15 cards, max 2 copies per floop)
      _createAxie('${prefix}_double_1', 'Soothing Doubletalk', AxieElementalClass.bird, 2, 10, 8, 'Doubletalk', 'Swallow', FloopSource.mouth, fDouble),
      _createAxie('${prefix}_double_2', 'Soothing Doubletalk', AxieElementalClass.bird, 2, 10, 8, 'Doubletalk', 'Swallow', FloopSource.mouth, fDouble),
      _createAxie('${prefix}_peace_1', 'Peace Dove', AxieElementalClass.bird, 2, 8, 10, 'Peace Maker', 'Feather Fan', FloopSource.mouth, fPeace),
      _createAxie('${prefix}_peace_2', 'Peace Dove', AxieElementalClass.bird, 2, 8, 10, 'Peace Maker', 'Feather Fan', FloopSource.mouth, fPeace),
      _createAxie('${prefix}_owl_1', 'Night Owl', AxieElementalClass.bird, 3, 20, 7, 'Little Owl', 'The Last One', FloopSource.mouth, fOwl),
      _createAxie('${prefix}_owl_2', 'Night Owl', AxieElementalClass.bird, 3, 20, 7, 'Little Owl', 'The Last One', FloopSource.mouth, fOwl),
      _createAxie('${prefix}_hungry_1', 'Hungry Bird', AxieElementalClass.bird, 1, 7, 3, 'Hungry Bird', 'Swallow', FloopSource.mouth, fHungry),
      _createAxie('${prefix}_hungry_2', 'Hungry Bird', AxieElementalClass.bird, 1, 7, 3, 'Hungry Bird', 'Swallow', FloopSource.mouth, fHungry),
      _createAxie('${prefix}_swallow_1', 'Storm Swallow', AxieElementalClass.bird, 2, 12, 6, 'Doubletalk', 'Swallow', FloopSource.tail, fSwallow),
      _createAxie('${prefix}_swallow_2', 'Storm Swallow', AxieElementalClass.bird, 2, 12, 6, 'Doubletalk', 'Swallow', FloopSource.tail, fSwallow),
      _createAxie('${prefix}_feather_1', 'Triple Feather', AxieElementalClass.bird, 3, 18, 9, 'Doubletalk', 'Feather Fan', FloopSource.tail, fFeather),
      _createAxie('${prefix}_feather_2', 'Triple Feather', AxieElementalClass.bird, 3, 18, 9, 'Doubletalk', 'Feather Fan', FloopSource.tail, fFeather),
      _createAxie('${prefix}_lastone_1', 'Last Falcon', AxieElementalClass.bird, 3, 21, 6, 'Little Owl', 'The Last One', FloopSource.tail, fLast),
      _createAxie('${prefix}_lastone_2', 'Last Falcon', AxieElementalClass.bird, 3, 21, 6, 'Little Owl', 'The Last One', FloopSource.tail, fLast),
      _createAxie('${prefix}_cloud_1', 'Cloud Floater', AxieElementalClass.bird, 1, 5, 5, 'Peace Maker', 'Cloud', FloopSource.tail, fCloud),

      // 5 Structures from structures_master.csv (str_12, str_28, str_22)
      _createStructure(
        id: '${prefix}_eyrie_1',
        name: 'Haunted Eyrie',
        manaCost: 4,
        maxHp: 22,
        armorReduction: 2,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 8,
        loreDescription: 'Creature in this lane gets +8 Attack and +8 Defense.',
        cardArtAssetId: 'asset_struct_haunted_eyrie',
      ),
      _createStructure(
        id: '${prefix}_eyrie_2',
        name: 'Haunted Eyrie',
        manaCost: 4,
        maxHp: 22,
        armorReduction: 2,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 8,
        loreDescription: 'Creature in this lane gets +8 Attack and +8 Defense.',
        cardArtAssetId: 'asset_struct_haunted_eyrie',
      ),
      _createStructure(
        id: '${prefix}_beacon_1',
        name: 'Solar Beacon',
        manaCost: 2,
        maxHp: 18,
        armorReduction: 1,
        effectType: BuildingEffectType.attackAura,
        rawEffectType: 'BUFF_ATK',
        effectValue: 4,
        activationTrigger: 'ON_FLOOP',
        loreDescription: 'Creature in this lane gets +4 Attack every time it activates an ability.',
        cardArtAssetId: 'asset_struct_solar_beacon',
      ),
      _createStructure(
        id: '${prefix}_beacon_2',
        name: 'Solar Beacon',
        manaCost: 2,
        maxHp: 18,
        armorReduction: 1,
        effectType: BuildingEffectType.attackAura,
        rawEffectType: 'BUFF_ATK',
        effectValue: 4,
        activationTrigger: 'ON_FLOOP',
        loreDescription: 'Creature in this lane gets +4 Attack every time it activates an ability.',
        cardArtAssetId: 'asset_struct_solar_beacon',
      ),
      _createStructure(
        id: '${prefix}_solarspire_1',
        name: 'Solar Spire',
        manaCost: 4,
        maxHp: 25,
        armorReduction: 3,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 5,
        loreDescription: 'Creature in this lane takes 5 less damage when attacked.',
        cardArtAssetId: 'asset_struct_solar_spire',
      ),

      // 5 Spells from spells_master.csv (spl_23, spl_15, spl_09)
      _createSpell(
        id: '${prefix}_fstrike_1',
        name: 'Feathered Strike',
        manaCost: 4,
        rawEffectType: 'DAMAGE',
        effectValue: 10,
        targetScope: 'HERO',
        rarity: 'EPIC',
        description: 'Deal 10 damage to opposing hero and restore 10 HP to your hero.',
        cardArtAssetId: 'asset_spell_feathered_strike',
      ),
      _createSpell(
        id: '${prefix}_fstrike_2',
        name: 'Feathered Strike',
        manaCost: 4,
        rawEffectType: 'DAMAGE',
        effectValue: 10,
        targetScope: 'HERO',
        rarity: 'EPIC',
        description: 'Deal 10 damage to opposing hero and restore 10 HP to your hero.',
        cardArtAssetId: 'asset_spell_feathered_strike',
      ),
      _createSpell(
        id: '${prefix}_astral_1',
        name: 'Falling Astral Star',
        manaCost: 2,
        rawEffectType: 'MANA_SURGE',
        effectValue: 2,
        targetScope: 'PLAYER',
        rarity: 'RARE',
        description: 'Opponent gets 2 less Energy next round.',
        cardArtAssetId: 'asset_spell_falling_astral_star',
      ),
      _createSpell(
        id: '${prefix}_astral_2',
        name: 'Falling Astral Star',
        manaCost: 2,
        rawEffectType: 'MANA_SURGE',
        effectValue: 2,
        targetScope: 'PLAYER',
        rarity: 'RARE',
        description: 'Opponent gets 2 less Energy next round.',
        cardArtAssetId: 'asset_spell_falling_astral_star',
      ),
      _createSpell(
        id: '${prefix}_daggerstorm_1',
        name: 'Clairvoyant Daggerstorm',
        manaCost: 2,
        rawEffectType: 'DAMAGE',
        effectValue: 5,
        rarity: 'RARE',
        description: 'Choose an enemy unit and double the damage taken on it.',
        cardArtAssetId: 'asset_spell_clairvoyant_daggerstorm',
      ),
    ];

    return DeckEntity(
      id: 'deck_pure_bird',
      name: 'Pure Bird (Sky Backdoor)',
      cards: cards,
      landscapes: const [
        BoardClassAffinity.bird,
        BoardClassAffinity.bird,
        BoardClassAffinity.bird,
        BoardClassAffinity.bird,
      ],
      isPreset: true,
      pureClass: AxieElementalClass.bird,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. PURE BUG DECK (Swamp / Disruption - 25 Cards)
  // ─────────────────────────────────────────────────────────────────────────────
  static DeckEntity bugPureDeck({String prefix = 'pure_bug'}) {
    final fMosq = _floopRepo.getFloopForPart(partName: 'Mosquito', partType: 'mouth', axieClass: AxieElementalClass.bug);
    final fBunny = _floopRepo.getFloopForPart(partName: 'Cute Bunny', partType: 'mouth', axieClass: AxieElementalClass.bug);
    final fSquare = _floopRepo.getFloopForPart(partName: 'Square Teeth', partType: 'mouth', axieClass: AxieElementalClass.bug);
    final fPincer = _floopRepo.getFloopForPart(partName: 'Pincer', partType: 'mouth', axieClass: AxieElementalClass.bug);
    final fAnt = _floopRepo.getFloopForPart(partName: 'Ant', partType: 'tail', axieClass: AxieElementalClass.bug);
    final fTwin = _floopRepo.getFloopForPart(partName: 'Twin Needle', partType: 'tail', axieClass: AxieElementalClass.bug);
    final fSnack = _floopRepo.getFloopForPart(partName: 'Fish Snack', partType: 'tail', axieClass: AxieElementalClass.bug);
    final fGravel = _floopRepo.getFloopForPart(partName: 'Gravel Ant', partType: 'tail', axieClass: AxieElementalClass.bug);

    final cards = <CombatCard>[
      // 15 Bug Axies (7 pairs + 1 single = 15 cards, max 2 copies per floop)
      _createAxie('${prefix}_mosq_1', 'Blood Mosquito', AxieElementalClass.bug, 2, 9, 9, 'Mosquito', 'Ant', FloopSource.mouth, fMosq),
      _createAxie('${prefix}_mosq_2', 'Blood Mosquito', AxieElementalClass.bug, 2, 9, 9, 'Mosquito', 'Ant', FloopSource.mouth, fMosq),
      _createAxie('${prefix}_bunny_1', 'Terror Bunny', AxieElementalClass.bug, 2, 8, 10, 'Cute Bunny', 'Twin Needle', FloopSource.mouth, fBunny),
      _createAxie('${prefix}_bunny_2', 'Terror Bunny', AxieElementalClass.bug, 2, 8, 10, 'Cute Bunny', 'Twin Needle', FloopSource.mouth, fBunny),
      _createAxie('${prefix}_square_1', 'Nut Squarer', AxieElementalClass.bug, 3, 18, 9, 'Square Teeth', 'Fish Snack', FloopSource.mouth, fSquare),
      _createAxie('${prefix}_square_2', 'Nut Squarer', AxieElementalClass.bug, 3, 18, 9, 'Square Teeth', 'Fish Snack', FloopSource.mouth, fSquare),
      _createAxie('${prefix}_pincer_1', 'Surgical Pincer', AxieElementalClass.bug, 2, 11, 7, 'Pincer', 'Gravel Ant', FloopSource.mouth, fPincer),
      _createAxie('${prefix}_pincer_2', 'Surgical Pincer', AxieElementalClass.bug, 2, 11, 7, 'Pincer', 'Gravel Ant', FloopSource.mouth, fPincer),
      _createAxie('${prefix}_ant_1', 'Acid Ant', AxieElementalClass.bug, 2, 9, 9, 'Mosquito', 'Ant', FloopSource.tail, fAnt),
      _createAxie('${prefix}_ant_2', 'Acid Ant', AxieElementalClass.bug, 2, 9, 9, 'Mosquito', 'Ant', FloopSource.tail, fAnt),
      _createAxie('${prefix}_twin_1', 'Double Stabber', AxieElementalClass.bug, 3, 17, 10, 'Square Teeth', 'Twin Needle', FloopSource.tail, fTwin),
      _createAxie('${prefix}_twin_2', 'Double Stabber', AxieElementalClass.bug, 3, 17, 10, 'Square Teeth', 'Twin Needle', FloopSource.tail, fTwin),
      _createAxie('${prefix}_snack_1', 'Anesthetic Bug', AxieElementalClass.bug, 2, 8, 10, 'Cute Bunny', 'Fish Snack', FloopSource.tail, fSnack),
      _createAxie('${prefix}_snack_2', 'Anesthetic Bug', AxieElementalClass.bug, 2, 8, 10, 'Cute Bunny', 'Fish Snack', FloopSource.tail, fSnack),
      _createAxie('${prefix}_gravel_1', 'Sand Trap Beetle', AxieElementalClass.bug, 2, 7, 11, 'Pincer', 'Gravel Ant', FloopSource.tail, fGravel),

      // 5 Structures from structures_master.csv (str_17, str_29, str_11)
      _createStructure(
        id: '${prefix}_chitin_1',
        name: 'Chitin Palace',
        manaCost: 2,
        maxHp: 14,
        armorReduction: 1,
        rawEffectType: 'DAMAGE_TRIGGER',
        effectValue: 5,
        activationTrigger: 'ON_SUMMON',
        targetScope: 'LANE_UNIT',
        loreDescription: 'Deal 5 damage to opposing creature when a new unit is deployed in this lane.',
        cardArtAssetId: 'asset_struct_chitin_palace',
      ),
      _createStructure(
        id: '${prefix}_chitin_2',
        name: 'Chitin Palace',
        manaCost: 2,
        maxHp: 14,
        armorReduction: 1,
        rawEffectType: 'DAMAGE_TRIGGER',
        effectValue: 5,
        activationTrigger: 'ON_SUMMON',
        targetScope: 'LANE_UNIT',
        loreDescription: 'Deal 5 damage to opposing creature when a new unit is deployed in this lane.',
        cardArtAssetId: 'asset_struct_chitin_palace',
      ),
      _createStructure(
        id: '${prefix}_bramble_1',
        name: 'Bramble Keep',
        manaCost: 2,
        maxHp: 16,
        armorReduction: 1,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 4,
        loreDescription: 'Creature in this lane gets +4 Attack and +4 Defense.',
        cardArtAssetId: 'asset_struct_bramble_keep',
      ),
      _createStructure(
        id: '${prefix}_bramble_2',
        name: 'Bramble Keep',
        manaCost: 2,
        maxHp: 16,
        armorReduction: 1,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 4,
        loreDescription: 'Creature in this lane gets +4 Attack and +4 Defense.',
        cardArtAssetId: 'asset_struct_bramble_keep',
      ),
      _createStructure(
        id: '${prefix}_reliquary_1',
        name: 'Bone Reliquary',
        manaCost: 1,
        maxHp: 10,
        armorReduction: 0,
        effectType: BuildingEffectType.attackAura,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        activationTrigger: 'ON_DESTROY',
        targetScope: 'LANE_UNIT',
        loreDescription: 'When creature in this lane is destroyed return it to hand and discard structure.',
        cardArtAssetId: 'asset_struct_bone_reliquary',
      ),

      // 5 Spells from spells_master.csv (spl_32, spl_18, spl_38)
      _createSpell(
        id: '${prefix}_incense_1',
        name: 'Bug Swarm Incense',
        manaCost: 3,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        targetScope: 'LANE',
        rarity: 'RARE',
        description: 'Target lane blocked from summoning next round.',
        cardArtAssetId: 'asset_spell_bug_swarm_incense',
      ),
      _createSpell(
        id: '${prefix}_incense_2',
        name: 'Bug Swarm Incense',
        manaCost: 3,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        targetScope: 'LANE',
        rarity: 'RARE',
        description: 'Target lane blocked from summoning next round.',
        cardArtAssetId: 'asset_spell_bug_swarm_incense',
      ),
      _createSpell(
        id: '${prefix}_csacrifice_1',
        name: 'Chitin Sacrifice',
        manaCost: 1,
        rawEffectType: 'DESTROY',
        effectValue: 1,
        description: 'Destroy one of your structures and draw 1 card.',
        cardArtAssetId: 'asset_spell_chitin_sacrifice',
      ),
      _createSpell(
        id: '${prefix}_csacrifice_2',
        name: 'Chitin Sacrifice',
        manaCost: 1,
        rawEffectType: 'DESTROY',
        effectValue: 1,
        description: 'Destroy one of your structures and draw 1 card.',
        cardArtAssetId: 'asset_spell_chitin_sacrifice',
      ),
      _createSpell(
        id: '${prefix}_darkchrys_1',
        name: 'Dark Chrysalis',
        manaCost: 1,
        rawEffectType: 'DESTROY',
        effectValue: 1,
        description: 'Destroy an allied creature to gain 4 Energy.',
        cardArtAssetId: 'asset_spell_dark_chrysalis',
      ),
    ];

    return DeckEntity(
      id: 'deck_pure_bug',
      name: 'Pure Bug (Swarm Disruption)',
      cards: cards,
      landscapes: const [
        BoardClassAffinity.bug,
        BoardClassAffinity.bug,
        BoardClassAffinity.bug,
        BoardClassAffinity.bug,
      ],
      isPreset: true,
      pureClass: AxieElementalClass.bug,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. PURE REPTILE DECK (Sand / Hardened Shells - 25 Cards)
  // ─────────────────────────────────────────────────────────────────────────────
  static DeckEntity reptilePureDeck({String prefix = 'pure_reptile'}) {
    final fTooth = _floopRepo.getFloopForPart(partName: 'Toothless Bite', partType: 'mouth', axieClass: AxieElementalClass.reptile);
    final fKotaro = _floopRepo.getFloopForPart(partName: 'Kotaro', partType: 'mouth', axieClass: AxieElementalClass.reptile);
    final fRazor = _floopRepo.getFloopForPart(partName: 'Razor Bite', partType: 'mouth', axieClass: AxieElementalClass.reptile);
    final fTurtle = _floopRepo.getFloopForPart(partName: 'Tiny Turtle', partType: 'mouth', axieClass: AxieElementalClass.reptile);
    final fGecko = _floopRepo.getFloopForPart(partName: 'Wall Gecko', partType: 'tail', axieClass: AxieElementalClass.reptile);
    final fIguana = _floopRepo.getFloopForPart(partName: 'Iguana', partType: 'tail', axieClass: AxieElementalClass.reptile);
    final fDino = _floopRepo.getFloopForPart(partName: 'Tiny Dino', partType: 'tail', axieClass: AxieElementalClass.reptile);
    final fSnake = _floopRepo.getFloopForPart(partName: 'Snake Jar', partType: 'tail', axieClass: AxieElementalClass.reptile);

    final cards = <CombatCard>[
      // 15 Reptile Axies (7 pairs + 1 single = 15 cards, max 2 copies per floop)
      _createAxie('${prefix}_tooth_1', 'Toothless Sneak', AxieElementalClass.reptile, 2, 8, 10, 'Toothless Bite', 'Wall Gecko', FloopSource.mouth, fTooth),
      _createAxie('${prefix}_tooth_2', 'Toothless Sneak', AxieElementalClass.reptile, 2, 8, 10, 'Toothless Bite', 'Wall Gecko', FloopSource.mouth, fTooth),
      _createAxie('${prefix}_kotaro_1', 'Kotaro Striker', AxieElementalClass.reptile, 2, 10, 8, 'Kotaro', 'Iguana', FloopSource.mouth, fKotaro),
      _createAxie('${prefix}_kotaro_2', 'Kotaro Striker', AxieElementalClass.reptile, 2, 10, 8, 'Kotaro', 'Iguana', FloopSource.mouth, fKotaro),
      _createAxie('${prefix}_razor_1', 'Razor Fang', AxieElementalClass.reptile, 3, 11, 16, 'Razor Bite', 'Tiny Dino', FloopSource.mouth, fRazor),
      _createAxie('${prefix}_razor_2', 'Razor Fang', AxieElementalClass.reptile, 3, 11, 16, 'Razor Bite', 'Tiny Dino', FloopSource.mouth, fRazor),
      _createAxie('${prefix}_turtle_1', 'Chomp Turtle', AxieElementalClass.reptile, 3, 9, 18, 'Tiny Turtle', 'Snake Jar', FloopSource.mouth, fTurtle),
      _createAxie('${prefix}_turtle_2', 'Chomp Turtle', AxieElementalClass.reptile, 3, 9, 18, 'Tiny Turtle', 'Snake Jar', FloopSource.mouth, fTurtle),
      _createAxie('${prefix}_gecko_1', 'Escaper Gecko', AxieElementalClass.reptile, 2, 7, 11, 'Toothless Bite', 'Wall Gecko', FloopSource.tail, fGecko),
      _createAxie('${prefix}_gecko_2', 'Escaper Gecko', AxieElementalClass.reptile, 2, 7, 11, 'Toothless Bite', 'Wall Gecko', FloopSource.tail, fGecko),
      _createAxie('${prefix}_iguana_1', 'Scale Dart Iguana', AxieElementalClass.reptile, 2, 10, 8, 'Kotaro', 'Iguana', FloopSource.tail, fIguana),
      _createAxie('${prefix}_iguana_2', 'Scale Dart Iguana', AxieElementalClass.reptile, 2, 10, 8, 'Kotaro', 'Iguana', FloopSource.tail, fIguana),
      _createAxie('${prefix}_dino_1', 'Tiny Dino Stomp', AxieElementalClass.reptile, 3, 16, 11, 'Razor Bite', 'Tiny Dino', FloopSource.tail, fDino),
      _createAxie('${prefix}_dino_2', 'Tiny Dino Stomp', AxieElementalClass.reptile, 3, 16, 11, 'Razor Bite', 'Tiny Dino', FloopSource.tail, fDino),
      _createAxie('${prefix}_snakejar_1', 'Jar Armor Reptile', AxieElementalClass.reptile, 3, 8, 19, 'Tiny Turtle', 'Snake Jar', FloopSource.tail, fSnake),

      // 5 Structures from structures_master.csv (str_14, str_20, str_02)
      _createStructure(
        id: '${prefix}_crypt_1',
        name: 'Reptilian Crypt',
        manaCost: 2,
        maxHp: 14,
        armorReduction: 1,
        effectType: BuildingEffectType.attackAura,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        activationTrigger: 'ON_DESTROY',
        targetScope: 'LANE_UNIT',
        loreDescription: 'When creature in this lane is destroyed return it to hand and discard structure.',
        cardArtAssetId: 'asset_struct_reptilian_crypt',
      ),
      _createStructure(
        id: '${prefix}_crypt_2',
        name: 'Reptilian Crypt',
        manaCost: 2,
        maxHp: 14,
        armorReduction: 1,
        effectType: BuildingEffectType.attackAura,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        activationTrigger: 'ON_DESTROY',
        targetScope: 'LANE_UNIT',
        loreDescription: 'When creature in this lane is destroyed return it to hand and discard structure.',
        cardArtAssetId: 'asset_struct_reptilian_crypt',
      ),
      _createStructure(
        id: '${prefix}_dbastion_1',
        name: 'Desert Bastion',
        manaCost: 2,
        maxHp: 16,
        armorReduction: 1,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 4,
        loreDescription: 'Creature in this lane gets +4 Attack and +4 Defense.',
        cardArtAssetId: 'asset_struct_desert_bastion',
      ),
      _createStructure(
        id: '${prefix}_dbastion_2',
        name: 'Desert Bastion',
        manaCost: 2,
        maxHp: 16,
        armorReduction: 1,
        effectType: BuildingEffectType.defenseAura,
        rawEffectType: 'BUFF_DEF',
        effectValue: 4,
        loreDescription: 'Creature in this lane gets +4 Attack and +4 Defense.',
        cardArtAssetId: 'asset_struct_desert_bastion',
      ),
      _createStructure(
        id: '${prefix}_spikespire_1',
        name: 'Spike Spire',
        manaCost: 3,
        maxHp: 15,
        armorReduction: 1,
        rawEffectType: 'DAMAGE_TRIGGER',
        effectValue: 5,
        activationTrigger: 'ON_DESTROY',
        targetScope: 'HERO',
        loreDescription: 'Deals 5 damage to opposing hero when a creature in this lane is destroyed.',
        cardArtAssetId: 'asset_struct_spike_spire',
      ),

      // 5 Spells from spells_master.csv (spl_05, spl_30, spl_31)
      _createSpell(
        id: '${prefix}_vscepter_1',
        name: 'Venomous Scepter',
        manaCost: 1,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        description: 'Choose a Reptile ally to strike opposing lane unit immediately.',
        cardArtAssetId: 'asset_spell_venomous_scepter',
      ),
      _createSpell(
        id: '${prefix}_vscepter_2',
        name: 'Venomous Scepter',
        manaCost: 1,
        rawEffectType: 'UTILITY',
        effectValue: 1,
        description: 'Choose a Reptile ally to strike opposing lane unit immediately.',
        cardArtAssetId: 'asset_spell_venomous_scepter',
      ),
      _createSpell(
        id: '${prefix}_vdistort_1',
        name: 'Venomous Distortion',
        manaCost: 2,
        rawEffectType: 'SWAP_STATS',
        effectValue: 0,
        rarity: 'RARE',
        description: 'Choose an opponent creature and swap its Attack and Defense values.',
        cardArtAssetId: 'asset_spell_venomous_distortion',
      ),
      _createSpell(
        id: '${prefix}_vdistort_2',
        name: 'Venomous Distortion',
        manaCost: 2,
        rawEffectType: 'SWAP_STATS',
        effectValue: 0,
        rarity: 'RARE',
        description: 'Choose an opponent creature and swap its Attack and Defense values.',
        cardArtAssetId: 'asset_spell_venomous_distortion',
      ),
      _createSpell(
        id: '${prefix}_serpenteye_1',
        name: 'Serpent Eye Ring',
        manaCost: 2,
        rawEffectType: 'DRAW',
        effectValue: 1,
        targetScope: 'PLAYER',
        rarity: 'RARE',
        description: 'Draw 1 card for each of your empty lanes.',
        cardArtAssetId: 'asset_spell_serpent_eye_ring',
      ),
    ];

    return DeckEntity(
      id: 'deck_pure_reptile',
      name: 'Pure Reptile (Hardened Shells)',
      cards: cards,
      landscapes: const [
        BoardClassAffinity.reptile,
        BoardClassAffinity.reptile,
        BoardClassAffinity.reptile,
        BoardClassAffinity.reptile,
      ],
      isPreset: true,
      pureClass: AxieElementalClass.reptile,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Internal Helpers
  // ─────────────────────────────────────────────────────────────────────────────
  static AxieCardEntity _createAxie(
    String id,
    String name,
    AxieElementalClass axieClass,
    int manaCost,
    int atk,
    int def,
    String mouthName,
    String tailName,
    FloopSource floopSource,
    FloopAbilityEntity floop,
  ) {
    return AxieCardEntity(
      id: id,
      name: name,
      axieClass: axieClass,
      level: 25,
      manaCost: manaCost,
      baseAtk: atk,
      baseDef: def,
      initialPips: (axieClass == AxieElementalClass.beast || axieClass == AxieElementalClass.bug) ? 1 : 0,
      maxPips: 3,
      mouthPartName: mouthName,
      tailPartName: tailName,
      selectedFloop: floopSource,
      spriteUrl: 'https://assets.axieinfinity.com/axies/${axieClass.name}/axie/axie-full-transparent.png',
      proxySpriteUrl: 'https://wsrv.nl/?url=${axieClass.name}',
      rawGenes: {'class': axieClass.name, 'name': name},
      floop: floop,
    );
  }

  static BuildingCardEntity _createStructure({
    required String id,
    required String name,
    required int manaCost,
    required int maxHp,
    required int armorReduction,
    BuildingEffectType? effectType,
    required String rawEffectType,
    required int effectValue,
    String activationTrigger = 'PASSIVE',
    String targetScope = 'LANE_UNIT',
    String loreDescription = '',
    String cardArtAssetId = '',
  }) {
    return BuildingCardEntity(
      id: id,
      name: name,
      axieClassAffinity: BoardClassAffinity.neutral,
      manaCost: manaCost,
      maxHp: maxHp,
      armorReduction: armorReduction,
      effectType: effectType ?? _parseBuildingEffect(rawEffectType),
      rawEffectType: rawEffectType,
      effectValue: effectValue,
      scalingFormula: 'NONE',
      activationTrigger: activationTrigger,
      targetScope: targetScope,
      loreDescription: loreDescription,
      cardArtAssetId: cardArtAssetId,
    );
  }

  static SpellCardEntity _createSpell({
    required String id,
    required String name,
    required int manaCost,
    SpellEffectType? effectType,
    required String rawEffectType,
    required int effectValue,
    SpellTargetType? targetType,
    String targetScope = 'SINGLE_CREATURE',
    String rarity = 'COMMON',
    String description = '',
    String cardArtAssetId = '',
  }) {
    return SpellCardEntity(
      id: id,
      name: name,
      axieClassAffinity: BoardClassAffinity.neutral,
      manaCost: manaCost,
      effectType: effectType ?? _parseSpellEffect(rawEffectType),
      rawEffectType: rawEffectType,
      effectValue: effectValue,
      targetType: targetType ?? _parseSpellTarget(targetScope, rawEffectType),
      targetScope: targetScope,
      scalingFormula: 'NONE',
      castWindow: 'ACTION_PHASE',
      rarity: rarity,
      description: description,
      cardArtAssetId: cardArtAssetId,
    );
  }

  static BuildingEffectType _parseBuildingEffect(String raw) {
    switch (raw.toUpperCase()) {
      case 'BUFF_ATK':
      case 'ATTACK_AURA':
        return BuildingEffectType.attackAura;
      case 'BUFF_DEF':
      case 'DEFENSE_AURA':
        return BuildingEffectType.defenseAura;
      case 'REPAIR':
      case 'ROUND_START_REPAIR':
        return BuildingEffectType.roundStartRepair;
      case 'DAMAGE':
      case 'DAMAGE_TRIGGER':
        return BuildingEffectType.damageTrigger;
      case 'SWAP_STATS':
        return BuildingEffectType.swapStats;
      default:
        return BuildingEffectType.utility;
    }
  }

  static SpellEffectType _parseSpellEffect(String raw) {
    switch (raw.toUpperCase()) {
      case 'DAMAGE':
      case 'DIRECT_DAMAGE':
      case 'DESTROY':
      case 'FATIGUE':
        return SpellEffectType.directDamage;
      case 'HEAL':
      case 'GRANT_DEF':
      case 'DEFENSE':
        return SpellEffectType.grantDef;
      case 'BUFF_ATK':
      case 'GRANT_ATK':
      case 'ATTACK':
        return SpellEffectType.grantAtk;
      case 'REPAIR':
      case 'REPAIR_BUILDING':
        return SpellEffectType.repairBuilding;
      default:
        return SpellEffectType.directDamage;
    }
  }

  static SpellTargetType _parseSpellTarget(String scope, String rawEffect) {
    final s = scope.toUpperCase();
    final e = rawEffect.toUpperCase();
    if (s.contains('HERO')) {
      return SpellTargetType.enemyHero;
    }
    if (s.contains('LANE')) {
      return SpellTargetType.laneSlot;
    }
    if (e == 'DAMAGE' || e == 'DESTROY' || e == 'SWAP_STATS') {
      return SpellTargetType.enemyUnit;
    }
    return SpellTargetType.alliedUnit;
  }
}
