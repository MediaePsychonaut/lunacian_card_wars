// ===============================================================================
// [MODULE_NAME]: pure_deck_catalog.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Services
// [INTENT]: Factory service providing the 6 canonical Pure Elemental Decks (Beast, Aquatic, Plant, Bird, Bug, Reptile) with 4 matching landscape tiles and valid floops.
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

  // 1. PURE BEAST DECK (Hay / Corn Aggro)
  static DeckEntity beastPureDeck({String prefix = 'pure_beast'}) {
    final fNut = _floopRepo.getFloopForPart(partName: 'Nutcracker', partType: 'mouth', axieClass: AxieElementalClass.beast);
    final fKiss = _floopRepo.getFloopForPart(partName: 'Axie Kiss', partType: 'mouth', axieClass: AxieElementalClass.beast);
    final fShiba = _floopRepo.getFloopForPart(partName: 'Shiba', partType: 'tail', axieClass: AxieElementalClass.beast);
    final fHare = _floopRepo.getFloopForPart(partName: 'Hare', partType: 'tail', axieClass: AxieElementalClass.beast);
    final fGoda = _floopRepo.getFloopForPart(partName: 'Goda', partType: 'mouth', axieClass: AxieElementalClass.beast);
    final fRice = _floopRepo.getFloopForPart(partName: 'Rice', partType: 'tail', axieClass: AxieElementalClass.beast);

    final cards = <CombatCard>[
      // 12 Beast Axies (2 copies each, total 6 distinct floops with max 2 copies each)
      _createAxie('${prefix}_nutcracker_1', 'Buba Nutcracker', AxieElementalClass.beast, 3, 17, 10, 'Nutcracker', 'Cottontail', FloopSource.mouth, fNut),
      _createAxie('${prefix}_nutcracker_2', 'Buba Nutcracker', AxieElementalClass.beast, 3, 17, 10, 'Nutcracker', 'Cottontail', FloopSource.mouth, fNut),
      _createAxie('${prefix}_kiss_1', 'Kissing Beast', AxieElementalClass.beast, 2, 12, 6, 'Axie Kiss', 'Gerbil', FloopSource.mouth, fKiss),
      _createAxie('${prefix}_kiss_2', 'Kissing Beast', AxieElementalClass.beast, 2, 12, 6, 'Axie Kiss', 'Gerbil', FloopSource.mouth, fKiss),
      _createAxie('${prefix}_shiba_1', 'Shiba Hunter', AxieElementalClass.beast, 3, 19, 8, 'Confident', 'Shiba', FloopSource.tail, fShiba),
      _createAxie('${prefix}_shiba_2', 'Shiba Hunter', AxieElementalClass.beast, 3, 19, 8, 'Confident', 'Shiba', FloopSource.tail, fShiba),
      _createAxie('${prefix}_hare_1', 'Hare Striker', AxieElementalClass.beast, 2, 11, 7, 'Confident', 'Hare', FloopSource.tail, fHare),
      _createAxie('${prefix}_hare_2', 'Hare Striker', AxieElementalClass.beast, 2, 11, 7, 'Confident', 'Hare', FloopSource.tail, fHare),
      _createAxie('${prefix}_goda_1', 'Howling Goda', AxieElementalClass.beast, 2, 10, 8, 'Goda', 'Cottontail', FloopSource.mouth, fGoda),
      _createAxie('${prefix}_goda_2', 'Howling Goda', AxieElementalClass.beast, 2, 10, 8, 'Goda', 'Cottontail', FloopSource.mouth, fGoda),
      _createAxie('${prefix}_rice_1', 'Night Rice', AxieElementalClass.beast, 2, 9, 9, 'Confident', 'Rice', FloopSource.tail, fRice),
      _createAxie('${prefix}_rice_2', 'Night Rice', AxieElementalClass.beast, 2, 9, 9, 'Confident', 'Rice', FloopSource.tail, fRice),

      // 4 Structures
      BuildingCardEntity.attackTotem(id: '${prefix}_struct_1'),
      BuildingCardEntity.attackTotem(id: '${prefix}_struct_2'),
      BuildingCardEntity.defenseBarricade(id: '${prefix}_struct_3'),
      BuildingCardEntity.vitalityShrine(id: '${prefix}_struct_4'),

      // 4 Spells
      SpellCardEntity.starShuriken(id: '${prefix}_spell_1'),
      SpellCardEntity.starShuriken(id: '${prefix}_spell_2'),
      SpellCardEntity.lunarBlessing(id: '${prefix}_spell_3'),
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_4'),
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

  // 2. PURE AQUATIC DECK (Blue / Water Tempo)
  static DeckEntity aquaticPureDeck({String prefix = 'pure_aqua'}) {
    final fLam = _floopRepo.getFloopForPart(partName: 'Lam', partType: 'mouth', axieClass: AxieElementalClass.aquatic);
    final fRisky = _floopRepo.getFloopForPart(partName: 'Risky Fish', partType: 'mouth', axieClass: AxieElementalClass.aquatic);
    final fCatfish = _floopRepo.getFloopForPart(partName: 'Catfish', partType: 'mouth', axieClass: AxieElementalClass.aquatic);
    final fKoi = _floopRepo.getFloopForPart(partName: 'Koi', partType: 'tail', axieClass: AxieElementalClass.aquatic);
    final fNimo = _floopRepo.getFloopForPart(partName: 'Nimo', partType: 'tail', axieClass: AxieElementalClass.aquatic);
    final fNavaga = _floopRepo.getFloopForPart(partName: 'Navaga', partType: 'tail', axieClass: AxieElementalClass.aquatic);

    final cards = <CombatCard>[
      _createAxie('${prefix}_lam_1', 'Puffy Lam', AxieElementalClass.aquatic, 3, 15, 12, 'Lam', 'Nimo', FloopSource.mouth, fLam),
      _createAxie('${prefix}_lam_2', 'Puffy Lam', AxieElementalClass.aquatic, 3, 15, 12, 'Lam', 'Nimo', FloopSource.mouth, fLam),
      _createAxie('${prefix}_risky_1', 'Risky Piranha', AxieElementalClass.aquatic, 2, 13, 5, 'Risky Fish', 'Koi', FloopSource.mouth, fRisky),
      _createAxie('${prefix}_risky_2', 'Risky Piranha', AxieElementalClass.aquatic, 2, 13, 5, 'Risky Fish', 'Koi', FloopSource.mouth, fRisky),
      _createAxie('${prefix}_catfish_1', 'Deep Catfish', AxieElementalClass.aquatic, 3, 12, 15, 'Catfish', 'Tadpole', FloopSource.mouth, fCatfish),
      _createAxie('${prefix}_catfish_2', 'Deep Catfish', AxieElementalClass.aquatic, 3, 12, 15, 'Catfish', 'Tadpole', FloopSource.mouth, fCatfish),
      _createAxie('${prefix}_koi_1', 'Upstream Koi', AxieElementalClass.aquatic, 2, 10, 8, 'Piranha', 'Koi', FloopSource.tail, fKoi),
      _createAxie('${prefix}_koi_2', 'Upstream Koi', AxieElementalClass.aquatic, 2, 10, 8, 'Piranha', 'Koi', FloopSource.tail, fKoi),
      _createAxie('${prefix}_nimo_1', 'Nimo Slapper', AxieElementalClass.aquatic, 2, 9, 9, 'Piranha', 'Nimo', FloopSource.tail, fNimo),
      _createAxie('${prefix}_nimo_2', 'Nimo Slapper', AxieElementalClass.aquatic, 2, 9, 9, 'Piranha', 'Nimo', FloopSource.tail, fNimo),
      _createAxie('${prefix}_navaga_1', 'Ice Navaga', AxieElementalClass.aquatic, 3, 16, 11, 'Piranha', 'Navaga', FloopSource.tail, fNavaga),
      _createAxie('${prefix}_navaga_2', 'Ice Navaga', AxieElementalClass.aquatic, 3, 16, 11, 'Piranha', 'Navaga', FloopSource.tail, fNavaga),

      // 4 Structures
      BuildingCardEntity.attackTotem(id: '${prefix}_struct_1'),
      BuildingCardEntity.defenseBarricade(id: '${prefix}_struct_2'),
      BuildingCardEntity.defenseBarricade(id: '${prefix}_struct_3'),
      BuildingCardEntity.vitalityShrine(id: '${prefix}_struct_4'),

      // 4 Spells
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_1'),
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_2'),
      SpellCardEntity.starShuriken(id: '${prefix}_spell_3'),
      SpellCardEntity.lunarBlessing(id: '${prefix}_spell_4'),
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

  // 3. PURE PLANT DECK (Green / Nice Sustain)
  static DeckEntity plantPureDeck({String prefix = 'pure_plant'}) {
    final fSerious = _floopRepo.getFloopForPart(partName: 'Serious', partType: 'mouth', axieClass: AxieElementalClass.plant);
    final fZigzag = _floopRepo.getFloopForPart(partName: 'Zigzag', partType: 'mouth', axieClass: AxieElementalClass.plant);
    final fHerb = _floopRepo.getFloopForPart(partName: 'Herbivore', partType: 'mouth', axieClass: AxieElementalClass.plant);
    final fCarrot = _floopRepo.getFloopForPart(partName: 'Carrot', partType: 'tail', axieClass: AxieElementalClass.plant);
    final fCattail = _floopRepo.getFloopForPart(partName: 'Cattail', partType: 'tail', axieClass: AxieElementalClass.plant);
    final fYam = _floopRepo.getFloopForPart(partName: 'Yam', partType: 'tail', axieClass: AxieElementalClass.plant);

    final cards = <CombatCard>[
      _createAxie('${prefix}_serious_1', 'Olek Serious', AxieElementalClass.plant, 3, 10, 17, 'Serious', 'Carrot', FloopSource.mouth, fSerious),
      _createAxie('${prefix}_serious_2', 'Olek Serious', AxieElementalClass.plant, 3, 10, 17, 'Serious', 'Carrot', FloopSource.mouth, fSerious),
      _createAxie('${prefix}_zigzag_1', 'Drain Zigzag', AxieElementalClass.plant, 2, 7, 11, 'Zigzag', 'Cattail', FloopSource.mouth, fZigzag),
      _createAxie('${prefix}_zigzag_2', 'Drain Zigzag', AxieElementalClass.plant, 2, 7, 11, 'Zigzag', 'Cattail', FloopSource.mouth, fZigzag),
      _createAxie('${prefix}_herb_1', 'Herbivore Wall', AxieElementalClass.plant, 3, 8, 19, 'Herbivore', 'Hatsune', FloopSource.mouth, fHerb),
      _createAxie('${prefix}_herb_2', 'Herbivore Wall', AxieElementalClass.plant, 3, 8, 19, 'Herbivore', 'Hatsune', FloopSource.mouth, fHerb),
      _createAxie('${prefix}_carrot_1', 'Carrot Guard', AxieElementalClass.plant, 2, 6, 12, 'Silence Whisper', 'Carrot', FloopSource.tail, fCarrot),
      _createAxie('${prefix}_carrot_2', 'Carrot Guard', AxieElementalClass.plant, 2, 6, 12, 'Silence Whisper', 'Carrot', FloopSource.tail, fCarrot),
      _createAxie('${prefix}_cattail_1', 'Cattail Ward', AxieElementalClass.plant, 2, 8, 10, 'Silence Whisper', 'Cattail', FloopSource.tail, fCattail),
      _createAxie('${prefix}_cattail_2', 'Cattail Ward', AxieElementalClass.plant, 2, 8, 10, 'Silence Whisper', 'Cattail', FloopSource.tail, fCattail),
      _createAxie('${prefix}_yam_1', 'Yam Spore', AxieElementalClass.plant, 2, 7, 11, 'Silence Whisper', 'Yam', FloopSource.tail, fYam),
      _createAxie('${prefix}_yam_2', 'Yam Spore', AxieElementalClass.plant, 2, 7, 11, 'Silence Whisper', 'Yam', FloopSource.tail, fYam),

      // 4 Structures
      BuildingCardEntity.defenseBarricade(id: '${prefix}_struct_1'),
      BuildingCardEntity.defenseBarricade(id: '${prefix}_struct_2'),
      BuildingCardEntity.vitalityShrine(id: '${prefix}_struct_3'),
      BuildingCardEntity.vitalityShrine(id: '${prefix}_struct_4'),

      // 4 Spells
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_1'),
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_2'),
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_3'),
      SpellCardEntity.lunarBlessing(id: '${prefix}_spell_4'),
    ];

    return DeckEntity(
      id: 'deck_pure_plant',
      name: 'Pure Plant (Green Sustain)',
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

  // 4. PURE BIRD DECK (Sky / Swamp Backdoor)
  static DeckEntity birdPureDeck({String prefix = 'pure_bird'}) {
    final fOwl = _floopRepo.getFloopForPart(partName: 'Little Owl', partType: 'mouth', axieClass: AxieElementalClass.bird);
    final fDouble = _floopRepo.getFloopForPart(partName: 'Doubletalk', partType: 'mouth', axieClass: AxieElementalClass.bird);
    final fPeace = _floopRepo.getFloopForPart(partName: 'Peace Maker', partType: 'mouth', axieClass: AxieElementalClass.bird);
    final fSwallow = _floopRepo.getFloopForPart(partName: 'Swallow', partType: 'tail', axieClass: AxieElementalClass.bird);
    final fFeather = _floopRepo.getFloopForPart(partName: 'Feather Fan', partType: 'tail', axieClass: AxieElementalClass.bird);
    final fLast = _floopRepo.getFloopForPart(partName: 'The Last One', partType: 'tail', axieClass: AxieElementalClass.bird);

    final cards = <CombatCard>[
      _createAxie('${prefix}_owl_1', 'Dark Owl', AxieElementalClass.bird, 3, 20, 7, 'Little Owl', 'Swallow', FloopSource.mouth, fOwl),
      _createAxie('${prefix}_owl_2', 'Dark Owl', AxieElementalClass.bird, 3, 20, 7, 'Little Owl', 'Swallow', FloopSource.mouth, fOwl),
      _createAxie('${prefix}_double_1', 'Lullaby Bird', AxieElementalClass.bird, 2, 11, 7, 'Doubletalk', 'Cloud', FloopSource.mouth, fDouble),
      _createAxie('${prefix}_double_2', 'Lullaby Bird', AxieElementalClass.bird, 2, 11, 7, 'Doubletalk', 'Cloud', FloopSource.mouth, fDouble),
      _createAxie('${prefix}_peace_1', 'Peace Raven', AxieElementalClass.bird, 2, 10, 8, 'Peace Maker', 'Cloud', FloopSource.mouth, fPeace),
      _createAxie('${prefix}_peace_2', 'Peace Raven', AxieElementalClass.bird, 2, 10, 8, 'Peace Maker', 'Cloud', FloopSource.mouth, fPeace),
      _createAxie('${prefix}_swallow_1', 'Storm Swallow', AxieElementalClass.bird, 3, 18, 9, 'Hungry Bird', 'Swallow', FloopSource.tail, fSwallow),
      _createAxie('${prefix}_swallow_2', 'Storm Swallow', AxieElementalClass.bird, 3, 18, 9, 'Hungry Bird', 'Swallow', FloopSource.tail, fSwallow),
      _createAxie('${prefix}_feather_1', 'Feather Fan Harrier', AxieElementalClass.bird, 2, 13, 5, 'Hungry Bird', 'Feather Fan', FloopSource.tail, fFeather),
      _createAxie('${prefix}_feather_2', 'Feather Fan Harrier', AxieElementalClass.bird, 2, 13, 5, 'Hungry Bird', 'Feather Fan', FloopSource.tail, fFeather),
      _createAxie('${prefix}_last_1', 'The Last Falcon', AxieElementalClass.bird, 3, 21, 6, 'Hungry Bird', 'The Last One', FloopSource.tail, fLast),
      _createAxie('${prefix}_last_2', 'The Last Falcon', AxieElementalClass.bird, 3, 21, 6, 'Hungry Bird', 'The Last One', FloopSource.tail, fLast),

      // 4 Structures
      BuildingCardEntity.attackTotem(id: '${prefix}_struct_1'),
      BuildingCardEntity.attackTotem(id: '${prefix}_struct_2'),
      BuildingCardEntity.defenseBarricade(id: '${prefix}_struct_3'),
      BuildingCardEntity.vitalityShrine(id: '${prefix}_struct_4'),

      // 4 Spells
      SpellCardEntity.starShuriken(id: '${prefix}_spell_1'),
      SpellCardEntity.starShuriken(id: '${prefix}_spell_2'),
      SpellCardEntity.lunarBlessing(id: '${prefix}_spell_3'),
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_4'),
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

  // 5. PURE BUG DECK (Swamp Disruption)
  static DeckEntity bugPureDeck({String prefix = 'pure_bug'}) {
    final fMosq = _floopRepo.getFloopForPart(partName: 'Mosquito', partType: 'mouth', axieClass: AxieElementalClass.bug);
    final fBunny = _floopRepo.getFloopForPart(partName: 'Cute Bunny', partType: 'mouth', axieClass: AxieElementalClass.bug);
    final fPincer = _floopRepo.getFloopForPart(partName: 'Pincer', partType: 'mouth', axieClass: AxieElementalClass.bug);
    final fAnt = _floopRepo.getFloopForPart(partName: 'Ant', partType: 'tail', axieClass: AxieElementalClass.bug);
    final fNeedle = _floopRepo.getFloopForPart(partName: 'Twin Needle', partType: 'tail', axieClass: AxieElementalClass.bug);
    final fPupae = _floopRepo.getFloopForPart(partName: 'Pupae', partType: 'tail', axieClass: AxieElementalClass.bug);

    final cards = <CombatCard>[
      _createAxie('${prefix}_mosq_1', 'Blood Mosquito', AxieElementalClass.bug, 2, 9, 9, 'Mosquito', 'Ant', FloopSource.mouth, fMosq),
      _createAxie('${prefix}_mosq_2', 'Blood Mosquito', AxieElementalClass.bug, 2, 9, 9, 'Mosquito', 'Ant', FloopSource.mouth, fMosq),
      _createAxie('${prefix}_bunny_1', 'Terror Bunny', AxieElementalClass.bug, 3, 13, 14, 'Cute Bunny', 'Pupae', FloopSource.mouth, fBunny),
      _createAxie('${prefix}_bunny_2', 'Terror Bunny', AxieElementalClass.bug, 3, 13, 14, 'Cute Bunny', 'Pupae', FloopSource.mouth, fBunny),
      _createAxie('${prefix}_pincer_1', 'Surgical Pincer', AxieElementalClass.bug, 2, 11, 7, 'Pincer', 'Fish Snack', FloopSource.mouth, fPincer),
      _createAxie('${prefix}_pincer_2', 'Surgical Pincer', AxieElementalClass.bug, 2, 11, 7, 'Pincer', 'Fish Snack', FloopSource.mouth, fPincer),
      _createAxie('${prefix}_ant_1', 'Chemical Ant', AxieElementalClass.bug, 2, 9, 9, 'Square Teeth', 'Ant', FloopSource.tail, fAnt),
      _createAxie('${prefix}_ant_2', 'Chemical Ant', AxieElementalClass.bug, 2, 9, 9, 'Square Teeth', 'Ant', FloopSource.tail, fAnt),
      _createAxie('${prefix}_needle_1', 'Twin Needle Beetle', AxieElementalClass.bug, 3, 18, 9, 'Square Teeth', 'Twin Needle', FloopSource.tail, fNeedle),
      _createAxie('${prefix}_needle_2', 'Twin Needle Beetle', AxieElementalClass.bug, 3, 18, 9, 'Square Teeth', 'Twin Needle', FloopSource.tail, fNeedle),
      _createAxie('${prefix}_pupae_1', 'Metamorph Pupae', AxieElementalClass.bug, 2, 6, 12, 'Square Teeth', 'Pupae', FloopSource.tail, fPupae),
      _createAxie('${prefix}_pupae_2', 'Metamorph Pupae', AxieElementalClass.bug, 2, 6, 12, 'Square Teeth', 'Pupae', FloopSource.tail, fPupae),

      // 4 Structures
      BuildingCardEntity.attackTotem(id: '${prefix}_struct_1'),
      BuildingCardEntity.defenseBarricade(id: '${prefix}_struct_2'),
      BuildingCardEntity.vitalityShrine(id: '${prefix}_struct_3'),
      BuildingCardEntity.vitalityShrine(id: '${prefix}_struct_4'),

      // 4 Spells
      SpellCardEntity.starShuriken(id: '${prefix}_spell_1'),
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_2'),
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_3'),
      SpellCardEntity.lunarBlessing(id: '${prefix}_spell_4'),
    ];

    return DeckEntity(
      id: 'deck_pure_bug',
      name: 'Pure Bug (Swamp Disruption)',
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

  // 6. PURE REPTILE DECK (Sand Attrition)
  static DeckEntity reptilePureDeck({String prefix = 'pure_reptile'}) {
    final fTooth = _floopRepo.getFloopForPart(partName: 'Toothless Bite', partType: 'mouth', axieClass: AxieElementalClass.reptile);
    final fKotaro = _floopRepo.getFloopForPart(partName: 'Kotaro', partType: 'mouth', axieClass: AxieElementalClass.reptile);
    final fRazor = _floopRepo.getFloopForPart(partName: 'Razor Bite', partType: 'mouth', axieClass: AxieElementalClass.reptile);
    final fWall = _floopRepo.getFloopForPart(partName: 'Wall Gecko', partType: 'tail', axieClass: AxieElementalClass.reptile);
    final fSnake = _floopRepo.getFloopForPart(partName: 'Snake Jar', partType: 'tail', axieClass: AxieElementalClass.reptile);
    final fGila = _floopRepo.getFloopForPart(partName: 'Gila', partType: 'tail', axieClass: AxieElementalClass.reptile);

    final cards = <CombatCard>[
      _createAxie('${prefix}_tooth_1', 'Sneaky Toothless', AxieElementalClass.reptile, 2, 8, 10, 'Toothless Bite', 'Wall Gecko', FloopSource.mouth, fTooth),
      _createAxie('${prefix}_tooth_2', 'Sneaky Toothless', AxieElementalClass.reptile, 2, 8, 10, 'Toothless Bite', 'Wall Gecko', FloopSource.mouth, fTooth),
      _createAxie('${prefix}_kotaro_1', 'Kotaro Biter', AxieElementalClass.reptile, 2, 9, 9, 'Kotaro', 'Iguana', FloopSource.mouth, fKotaro),
      _createAxie('${prefix}_kotaro_2', 'Kotaro Biter', AxieElementalClass.reptile, 2, 9, 9, 'Kotaro', 'Iguana', FloopSource.mouth, fKotaro),
      _createAxie('${prefix}_razor_1', 'Venom Razor', AxieElementalClass.reptile, 3, 14, 13, 'Razor Bite', 'Snake Jar', FloopSource.mouth, fRazor),
      _createAxie('${prefix}_razor_2', 'Venom Razor', AxieElementalClass.reptile, 3, 14, 13, 'Razor Bite', 'Snake Jar', FloopSource.mouth, fRazor),
      _createAxie('${prefix}_wall_1', 'Gecko Sentinel', AxieElementalClass.reptile, 2, 7, 11, 'Tiny Turtle', 'Wall Gecko', FloopSource.tail, fWall),
      _createAxie('${prefix}_wall_2', 'Gecko Sentinel', AxieElementalClass.reptile, 2, 7, 11, 'Tiny Turtle', 'Wall Gecko', FloopSource.tail, fWall),
      _createAxie('${prefix}_snake_1', 'Jar Armored Reptile', AxieElementalClass.reptile, 3, 11, 16, 'Tiny Turtle', 'Snake Jar', FloopSource.tail, fSnake),
      _createAxie('${prefix}_snake_2', 'Jar Armored Reptile', AxieElementalClass.reptile, 3, 11, 16, 'Tiny Turtle', 'Snake Jar', FloopSource.tail, fSnake),
      _createAxie('${prefix}_gila_1', 'Gila Neurotoxin', AxieElementalClass.reptile, 3, 13, 14, 'Tiny Turtle', 'Gila', FloopSource.tail, fGila),
      _createAxie('${prefix}_gila_2', 'Gila Neurotoxin', AxieElementalClass.reptile, 3, 13, 14, 'Tiny Turtle', 'Gila', FloopSource.tail, fGila),

      // 4 Structures
      BuildingCardEntity.defenseBarricade(id: '${prefix}_struct_1'),
      BuildingCardEntity.defenseBarricade(id: '${prefix}_struct_2'),
      BuildingCardEntity.vitalityShrine(id: '${prefix}_struct_3'),
      BuildingCardEntity.attackTotem(id: '${prefix}_struct_4'),

      // 4 Spells
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_1'),
      SpellCardEntity.potionOfVitality(id: '${prefix}_spell_2'),
      SpellCardEntity.starShuriken(id: '${prefix}_spell_3'),
      SpellCardEntity.lunarBlessing(id: '${prefix}_spell_4'),
    ];

    return DeckEntity(
      id: 'deck_pure_reptile',
      name: 'Pure Reptile (Sand Attrition)',
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
}
