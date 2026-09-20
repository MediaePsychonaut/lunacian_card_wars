// ===============================================================================
// [MODULE_NAME]: fetch_axie_census.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Tool / Census
// [INTENT]: Pure Dart CLI script querying Sky Mavis GraphQL API to extract on-chain minted population census for 204 anatomical parts and 288 mouth-tail genetic permutations across pure and hybrid classes with dynamic candidate slug resolution.
// [DEPENDENCIES]: dart:io, dart:convert, package:http/http.dart
// [ARCHITECTURE]: Standalone CLI Data Extraction Script
// ===============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Anatomical slot definition.
enum BodySlot {
  horn('Horn'),
  back('Back'),
  mouth('Mouth'),
  tail('Tail'),
  eyes('Eyes'),
  ears('Ears');

  final String label;
  const BodySlot(this.label);
}

/// Pure Axie class definition.
enum AxieClass {
  beast('Beast'),
  aquatic('Aquatic'),
  plant('Plant'),
  bird('Bird'),
  bug('Bug'),
  reptile('Reptile');

  final String label;
  const AxieClass(this.label);
}

/// Anatomical part metadata model supporting fallback candidate slugs.
class PartDefinition {
  final String name;
  final BodySlot slot;
  final AxieClass axieClass;
  final List<String> candidateSlugs;

  const PartDefinition({
    required this.name,
    required this.slot,
    required this.axieClass,
    required this.candidateSlugs,
  });
}

/// Resolved part outcome linking definition to active slug and population count.
class ResolvedPart {
  final PartDefinition definition;
  final String resolvedSlug;
  final int count;

  const ResolvedPart({
    required this.definition,
    required this.resolvedSlug,
    required this.count,
  });
}

/// Genetic permutation record with classification metadata.
class PermutationRecord {
  final String mouthSlug;
  final String tailSlug;
  final String type; // 'Pure' or 'Mix'
  final String classification; // 'Beast', 'Aquatic', 'Plant', 'Bird', 'Bug', 'Reptile', 'Mech', 'Dusk', 'Dawn'

  const PermutationRecord({
    required this.mouthSlug,
    required this.tailSlug,
    required this.type,
    required this.classification,
  });

  String get key => '${mouthSlug}__$tailSlug';
}

/// Canonical catalog of all 204 physical anatomical parts in Axie Infinity.
/// Incorporates candidate slugs for on-chain slug reconciliation.
const List<PartDefinition> kAxiePartsCatalog = [
  // ==========================================
  // HORNS (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Horns (6)
  PartDefinition(name: 'Little Branch', slot: BodySlot.horn, axieClass: AxieClass.beast, candidateSlugs: ['horn-little-branch']),
  PartDefinition(name: 'Imp', slot: BodySlot.horn, axieClass: AxieClass.beast, candidateSlugs: ['horn-imp']),
  PartDefinition(name: 'Merry', slot: BodySlot.horn, axieClass: AxieClass.beast, candidateSlugs: ['horn-merry']),
  PartDefinition(name: 'Pocky', slot: BodySlot.horn, axieClass: AxieClass.beast, candidateSlugs: ['horn-pocky']),
  PartDefinition(name: 'Dual Blade', slot: BodySlot.horn, axieClass: AxieClass.beast, candidateSlugs: ['horn-dual-blade']),
  PartDefinition(name: 'Arco', slot: BodySlot.horn, axieClass: AxieClass.beast, candidateSlugs: ['horn-arco']),

  // Aquatic Horns (6)
  PartDefinition(name: 'Babylonia', slot: BodySlot.horn, axieClass: AxieClass.aquatic, candidateSlugs: ['horn-babylonia']),
  PartDefinition(name: 'Teal Shell', slot: BodySlot.horn, axieClass: AxieClass.aquatic, candidateSlugs: ['horn-teal-shell']),
  PartDefinition(name: 'Clamshell', slot: BodySlot.horn, axieClass: AxieClass.aquatic, candidateSlugs: ['horn-clamshell']),
  PartDefinition(name: 'Anemone', slot: BodySlot.horn, axieClass: AxieClass.aquatic, candidateSlugs: ['horn-anemone']),
  PartDefinition(name: 'Oranda', slot: BodySlot.horn, axieClass: AxieClass.aquatic, candidateSlugs: ['horn-oranda']),
  PartDefinition(name: 'Shoal Star', slot: BodySlot.horn, axieClass: AxieClass.aquatic, candidateSlugs: ['horn-shoal-star']),

  // Plant Horns (6)
  PartDefinition(name: 'Bamboo', slot: BodySlot.horn, axieClass: AxieClass.plant, candidateSlugs: ['horn-bamboo-shoot', 'horn-bamboo']),
  PartDefinition(name: 'Beech', slot: BodySlot.horn, axieClass: AxieClass.plant, candidateSlugs: ['horn-beech']),
  PartDefinition(name: 'Rose Bud', slot: BodySlot.horn, axieClass: AxieClass.plant, candidateSlugs: ['horn-rose-bud']),
  PartDefinition(name: 'Strawberry Shortcake', slot: BodySlot.horn, axieClass: AxieClass.plant, candidateSlugs: ['horn-strawberry-shortcake']),
  PartDefinition(name: 'Cactus', slot: BodySlot.horn, axieClass: AxieClass.plant, candidateSlugs: ['horn-cactus']),
  PartDefinition(name: 'Watermelon', slot: BodySlot.horn, axieClass: AxieClass.plant, candidateSlugs: ['horn-watermelon']),

  // Bird Horns (6)
  PartDefinition(name: 'Eggshell', slot: BodySlot.horn, axieClass: AxieClass.bird, candidateSlugs: ['horn-eggshell']),
  PartDefinition(name: 'Cuckoo', slot: BodySlot.horn, axieClass: AxieClass.bird, candidateSlugs: ['horn-cuckoo']),
  PartDefinition(name: 'Trump', slot: BodySlot.horn, axieClass: AxieClass.bird, candidateSlugs: ['horn-trump']),
  PartDefinition(name: 'Kestrel', slot: BodySlot.horn, axieClass: AxieClass.bird, candidateSlugs: ['horn-kestrel']),
  PartDefinition(name: 'Wing Horn', slot: BodySlot.horn, axieClass: AxieClass.bird, candidateSlugs: ['horn-wing-horn']),
  PartDefinition(name: 'Feather Spear', slot: BodySlot.horn, axieClass: AxieClass.bird, candidateSlugs: ['horn-feather-spear']),

  // Bug Horns (6)
  PartDefinition(name: 'Vall Ein', slot: BodySlot.horn, axieClass: AxieClass.bug, candidateSlugs: ['horn-lagging', 'horn-mystic-rush', 'horn-vall-ein']),
  PartDefinition(name: 'Antenna', slot: BodySlot.horn, axieClass: AxieClass.bug, candidateSlugs: ['horn-antenna']),
  PartDefinition(name: 'Caterpillar', slot: BodySlot.horn, axieClass: AxieClass.bug, candidateSlugs: ['horn-caterpillars', 'horn-dente', 'horn-pupa', 'horn-caterpillar']),
  PartDefinition(name: 'Pliers', slot: BodySlot.horn, axieClass: AxieClass.bug, candidateSlugs: ['horn-pliers']),
  PartDefinition(name: 'Parasite', slot: BodySlot.horn, axieClass: AxieClass.bug, candidateSlugs: ['horn-parasite']),
  PartDefinition(name: 'Leaf Bug', slot: BodySlot.horn, axieClass: AxieClass.bug, candidateSlugs: ['horn-leaf-bug']),

  // Reptile Horns (6)
  PartDefinition(name: 'Unko', slot: BodySlot.horn, axieClass: AxieClass.reptile, candidateSlugs: ['horn-unko']),
  PartDefinition(name: 'Scaly Spear', slot: BodySlot.horn, axieClass: AxieClass.reptile, candidateSlugs: ['horn-scaly-spear']),
  PartDefinition(name: 'Cerastes', slot: BodySlot.horn, axieClass: AxieClass.reptile, candidateSlugs: ['horn-cerastes']),
  PartDefinition(name: 'Scaly Spoon', slot: BodySlot.horn, axieClass: AxieClass.reptile, candidateSlugs: ['horn-scaly-spoon']),
  PartDefinition(name: 'Incisor', slot: BodySlot.horn, axieClass: AxieClass.reptile, candidateSlugs: ['horn-incisor']),
  PartDefinition(name: 'Bumpy', slot: BodySlot.horn, axieClass: AxieClass.reptile, candidateSlugs: ['horn-bumpy']),

  // ==========================================
  // BACKS (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Backs (6)
  PartDefinition(name: 'Ronin', slot: BodySlot.back, axieClass: AxieClass.beast, candidateSlugs: ['back-ronin']),
  PartDefinition(name: 'Hero', slot: BodySlot.back, axieClass: AxieClass.beast, candidateSlugs: ['back-hero']),
  PartDefinition(name: 'Jaguar', slot: BodySlot.back, axieClass: AxieClass.beast, candidateSlugs: ['back-jaguar']),
  PartDefinition(name: 'Risky Beast', slot: BodySlot.back, axieClass: AxieClass.beast, candidateSlugs: ['back-risky-beast']),
  PartDefinition(name: 'Timber', slot: BodySlot.back, axieClass: AxieClass.beast, candidateSlugs: ['back-timber']),
  PartDefinition(name: 'Furball', slot: BodySlot.back, axieClass: AxieClass.beast, candidateSlugs: ['back-furball']),

  // Aquatic Backs (6)
  PartDefinition(name: 'Hermit', slot: BodySlot.back, axieClass: AxieClass.aquatic, candidateSlugs: ['back-hermit']),
  PartDefinition(name: 'Blue Moon', slot: BodySlot.back, axieClass: AxieClass.aquatic, candidateSlugs: ['back-blue-moon']),
  PartDefinition(name: 'Goldfish', slot: BodySlot.back, axieClass: AxieClass.aquatic, candidateSlugs: ['back-goldfish']),
  PartDefinition(name: 'Sponge', slot: BodySlot.back, axieClass: AxieClass.aquatic, candidateSlugs: ['back-sponge']),
  PartDefinition(name: 'Anemone', slot: BodySlot.back, axieClass: AxieClass.aquatic, candidateSlugs: ['back-anemone']),
  PartDefinition(name: 'Perch', slot: BodySlot.back, axieClass: AxieClass.aquatic, candidateSlugs: ['back-perch']),

  // Plant Backs (6)
  PartDefinition(name: 'Turnip', slot: BodySlot.back, axieClass: AxieClass.plant, candidateSlugs: ['back-turnip']),
  PartDefinition(name: 'Shiitake', slot: BodySlot.back, axieClass: AxieClass.plant, candidateSlugs: ['back-shiitake']),
  PartDefinition(name: 'Bidens', slot: BodySlot.back, axieClass: AxieClass.plant, candidateSlugs: ['back-bidens']),
  PartDefinition(name: 'Watering Can', slot: BodySlot.back, axieClass: AxieClass.plant, candidateSlugs: ['back-watering-can']),
  PartDefinition(name: 'Mint', slot: BodySlot.back, axieClass: AxieClass.plant, candidateSlugs: ['back-mint']),
  PartDefinition(name: 'Pumpkin', slot: BodySlot.back, axieClass: AxieClass.plant, candidateSlugs: ['back-pumpkin']),

  // Bird Backs (6)
  PartDefinition(name: 'Pigeon Post', slot: BodySlot.back, axieClass: AxieClass.bird, candidateSlugs: ['back-pigeon-post']),
  PartDefinition(name: 'Raven', slot: BodySlot.back, axieClass: AxieClass.bird, candidateSlugs: ['back-raven']),
  PartDefinition(name: 'Cupid', slot: BodySlot.back, axieClass: AxieClass.bird, candidateSlugs: ['back-cupid']),
  PartDefinition(name: 'Kingfisher', slot: BodySlot.back, axieClass: AxieClass.bird, candidateSlugs: ['back-kingfisher']),
  PartDefinition(name: 'Tri Feather', slot: BodySlot.back, axieClass: AxieClass.bird, candidateSlugs: ['back-tri-feather']),
  PartDefinition(name: 'Balloon', slot: BodySlot.back, axieClass: AxieClass.bird, candidateSlugs: ['back-balloon']),

  // Bug Backs (6)
  PartDefinition(name: 'Snail Shell', slot: BodySlot.back, axieClass: AxieClass.bug, candidateSlugs: ['back-snail-shell']),
  PartDefinition(name: 'Garish Worm', slot: BodySlot.back, axieClass: AxieClass.bug, candidateSlugs: ['back-garish-worm']),
  PartDefinition(name: 'Buzz Buzz', slot: BodySlot.back, axieClass: AxieClass.bug, candidateSlugs: ['back-buzz-buzz']),
  PartDefinition(name: 'Sandal', slot: BodySlot.back, axieClass: AxieClass.bug, candidateSlugs: ['back-sandal']),
  PartDefinition(name: 'Scarab', slot: BodySlot.back, axieClass: AxieClass.bug, candidateSlugs: ['back-scarab']),
  PartDefinition(name: 'Spiky Wing', slot: BodySlot.back, axieClass: AxieClass.bug, candidateSlugs: ['back-spiky-wing']),

  // Reptile Backs (6)
  PartDefinition(name: 'Bone Sail', slot: BodySlot.back, axieClass: AxieClass.reptile, candidateSlugs: ['back-bone-sail']),
  PartDefinition(name: 'Tri Spikes', slot: BodySlot.back, axieClass: AxieClass.reptile, candidateSlugs: ['back-tri-spikes']),
  PartDefinition(name: 'Green Thorns', slot: BodySlot.back, axieClass: AxieClass.reptile, candidateSlugs: ['back-green-thorns']),
  PartDefinition(name: 'Indian Star', slot: BodySlot.back, axieClass: AxieClass.reptile, candidateSlugs: ['back-indian-star']),
  PartDefinition(name: 'Red Ear', slot: BodySlot.back, axieClass: AxieClass.reptile, candidateSlugs: ['back-red-ear']),
  PartDefinition(name: 'Croc', slot: BodySlot.back, axieClass: AxieClass.reptile, candidateSlugs: ['back-croc']),

  // ==========================================
  // MOUTHS (24 parts: 4 per class * 6 classes)
  // ==========================================
  // Beast Mouths (4)
  PartDefinition(name: 'Nutcracker', slot: BodySlot.mouth, axieClass: AxieClass.beast, candidateSlugs: ['mouth-nut-cracker']),
  PartDefinition(name: 'Axie Kiss', slot: BodySlot.mouth, axieClass: AxieClass.beast, candidateSlugs: ['mouth-axie-kiss']),
  PartDefinition(name: 'Goda', slot: BodySlot.mouth, axieClass: AxieClass.beast, candidateSlugs: ['mouth-goda']),
  PartDefinition(name: 'Confident', slot: BodySlot.mouth, axieClass: AxieClass.beast, candidateSlugs: ['mouth-confident']),

  // Aquatic Mouths (4)
  PartDefinition(name: 'Lam', slot: BodySlot.mouth, axieClass: AxieClass.aquatic, candidateSlugs: ['mouth-lam']),
  PartDefinition(name: 'Risky Fish', slot: BodySlot.mouth, axieClass: AxieClass.aquatic, candidateSlugs: ['mouth-risky-fish']),
  PartDefinition(name: 'Piranha', slot: BodySlot.mouth, axieClass: AxieClass.aquatic, candidateSlugs: ['mouth-piranha']),
  PartDefinition(name: 'Catfish', slot: BodySlot.mouth, axieClass: AxieClass.aquatic, candidateSlugs: ['mouth-catfish']),

  // Plant Mouths (4)
  PartDefinition(name: 'Serious', slot: BodySlot.mouth, axieClass: AxieClass.plant, candidateSlugs: ['mouth-serious']),
  PartDefinition(name: 'Zigzag', slot: BodySlot.mouth, axieClass: AxieClass.plant, candidateSlugs: ['mouth-zigzag']),
  PartDefinition(name: 'Herbivore', slot: BodySlot.mouth, axieClass: AxieClass.plant, candidateSlugs: ['mouth-herbivore']),
  PartDefinition(name: 'Silence Whisper', slot: BodySlot.mouth, axieClass: AxieClass.plant, candidateSlugs: ['mouth-silence-whisper']),

  // Bird Mouths (4)
  PartDefinition(name: 'Doubletalk', slot: BodySlot.mouth, axieClass: AxieClass.bird, candidateSlugs: ['mouth-doubletalk']),
  PartDefinition(name: 'Peace Maker', slot: BodySlot.mouth, axieClass: AxieClass.bird, candidateSlugs: ['mouth-peace-maker']),
  PartDefinition(name: 'Little Owl', slot: BodySlot.mouth, axieClass: AxieClass.bird, candidateSlugs: ['mouth-little-owl']),
  PartDefinition(name: 'Hungry Bird', slot: BodySlot.mouth, axieClass: AxieClass.bird, candidateSlugs: ['mouth-hungry-bird']),

  // Bug Mouths (4)
  PartDefinition(name: 'Mosquito', slot: BodySlot.mouth, axieClass: AxieClass.bug, candidateSlugs: ['mouth-mosquito']),
  PartDefinition(name: 'Cute Bunny', slot: BodySlot.mouth, axieClass: AxieClass.bug, candidateSlugs: ['mouth-cute-bunny']),
  PartDefinition(name: 'Square Teeth', slot: BodySlot.mouth, axieClass: AxieClass.bug, candidateSlugs: ['mouth-square-teeth']),
  PartDefinition(name: 'Pincer', slot: BodySlot.mouth, axieClass: AxieClass.bug, candidateSlugs: ['mouth-pincer']),

  // Reptile Mouths (4)
  PartDefinition(name: 'Toothless Bite', slot: BodySlot.mouth, axieClass: AxieClass.reptile, candidateSlugs: ['mouth-toothless-bite']),
  PartDefinition(name: 'Kotaro', slot: BodySlot.mouth, axieClass: AxieClass.reptile, candidateSlugs: ['mouth-kotaro']),
  PartDefinition(name: 'Razor Bite', slot: BodySlot.mouth, axieClass: AxieClass.reptile, candidateSlugs: ['mouth-razor-bite']),
  PartDefinition(name: 'Tiny Turtle', slot: BodySlot.mouth, axieClass: AxieClass.reptile, candidateSlugs: ['mouth-tiny-turtle']),

  // ==========================================
  // TAILS (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Tails (6)
  PartDefinition(name: 'Cottontail', slot: BodySlot.tail, axieClass: AxieClass.beast, candidateSlugs: ['tail-cottontail']),
  PartDefinition(name: 'Rice', slot: BodySlot.tail, axieClass: AxieClass.beast, candidateSlugs: ['tail-rice']),
  PartDefinition(name: 'Shiba', slot: BodySlot.tail, axieClass: AxieClass.beast, candidateSlugs: ['tail-shiba', 'tail-shiva']),
  PartDefinition(name: 'Gerbil', slot: BodySlot.tail, axieClass: AxieClass.beast, candidateSlugs: ['tail-gerbil']),
  PartDefinition(name: 'Hare', slot: BodySlot.tail, axieClass: AxieClass.beast, candidateSlugs: ['tail-hare']),
  PartDefinition(name: 'Nutcracker', slot: BodySlot.tail, axieClass: AxieClass.beast, candidateSlugs: ['tail-nut-cracker']),

  // Aquatic Tails (6)
  PartDefinition(name: 'Koi', slot: BodySlot.tail, axieClass: AxieClass.aquatic, candidateSlugs: ['tail-koi']),
  PartDefinition(name: 'Nimo', slot: BodySlot.tail, axieClass: AxieClass.aquatic, candidateSlugs: ['tail-nimo']),
  PartDefinition(name: 'Tadpole', slot: BodySlot.tail, axieClass: AxieClass.aquatic, candidateSlugs: ['tail-tadpole']),
  PartDefinition(name: 'Ranchu', slot: BodySlot.tail, axieClass: AxieClass.aquatic, candidateSlugs: ['tail-ranchu']),
  PartDefinition(name: 'Navaga', slot: BodySlot.tail, axieClass: AxieClass.aquatic, candidateSlugs: ['tail-navaga']),
  PartDefinition(name: 'Shrimp', slot: BodySlot.tail, axieClass: AxieClass.aquatic, candidateSlugs: ['tail-shrimp']),

  // Plant Tails (6)
  PartDefinition(name: 'Carrot', slot: BodySlot.tail, axieClass: AxieClass.plant, candidateSlugs: ['tail-carrot']),
  PartDefinition(name: 'Cattail', slot: BodySlot.tail, axieClass: AxieClass.plant, candidateSlugs: ['tail-cattail']),
  PartDefinition(name: 'Hatsune', slot: BodySlot.tail, axieClass: AxieClass.plant, candidateSlugs: ['tail-hatsune']),
  PartDefinition(name: 'Yam', slot: BodySlot.tail, axieClass: AxieClass.plant, candidateSlugs: ['tail-yam']),
  PartDefinition(name: 'Potato Leaf', slot: BodySlot.tail, axieClass: AxieClass.plant, candidateSlugs: ['tail-potato-leaf']),
  PartDefinition(name: 'Hot Butt', slot: BodySlot.tail, axieClass: AxieClass.plant, candidateSlugs: ['tail-hot-butt']),

  // Bird Tails (6)
  PartDefinition(name: 'Swallow', slot: BodySlot.tail, axieClass: AxieClass.bird, candidateSlugs: ['tail-swallow']),
  PartDefinition(name: 'Feather Fan', slot: BodySlot.tail, axieClass: AxieClass.bird, candidateSlugs: ['tail-feather-fan']),
  PartDefinition(name: 'The Last One', slot: BodySlot.tail, axieClass: AxieClass.bird, candidateSlugs: ['tail-the-last-one']),
  PartDefinition(name: 'Cloud', slot: BodySlot.tail, axieClass: AxieClass.bird, candidateSlugs: ['tail-cloud']),
  PartDefinition(name: 'Granma\'s Fan', slot: BodySlot.tail, axieClass: AxieClass.bird, candidateSlugs: ['tail-granmas-fan']),
  PartDefinition(name: 'Post Fight', slot: BodySlot.tail, axieClass: AxieClass.bird, candidateSlugs: ['tail-post-fight']),

  // Bug Tails (6)
  PartDefinition(name: 'Ant', slot: BodySlot.tail, axieClass: AxieClass.bug, candidateSlugs: ['tail-ant']),
  PartDefinition(name: 'Twin Needle', slot: BodySlot.tail, axieClass: AxieClass.bug, candidateSlugs: ['tail-twin-tail', 'tail-twin-needles', 'tail-twinneedle', 'tail-twin-needle']),
  PartDefinition(name: 'Fish Snack', slot: BodySlot.tail, axieClass: AxieClass.bug, candidateSlugs: ['tail-fish-snack']),
  PartDefinition(name: 'Gravel Ant', slot: BodySlot.tail, axieClass: AxieClass.bug, candidateSlugs: ['tail-gravel-ant']),
  PartDefinition(name: 'Pupae', slot: BodySlot.tail, axieClass: AxieClass.bug, candidateSlugs: ['tail-pupae']),
  PartDefinition(name: 'Thorny Caterpillar', slot: BodySlot.tail, axieClass: AxieClass.bug, candidateSlugs: ['tail-thorny-caterpillar']),

  // Reptile Tails (6)
  PartDefinition(name: 'Wall Gecko', slot: BodySlot.tail, axieClass: AxieClass.reptile, candidateSlugs: ['tail-wall-gecko']),
  PartDefinition(name: 'Iguana', slot: BodySlot.tail, axieClass: AxieClass.reptile, candidateSlugs: ['tail-iguana']),
  PartDefinition(name: 'Tiny Dino', slot: BodySlot.tail, axieClass: AxieClass.reptile, candidateSlugs: ['tail-tiny-dino']),
  PartDefinition(name: 'Snake Jar', slot: BodySlot.tail, axieClass: AxieClass.reptile, candidateSlugs: ['tail-snake-jar']),
  PartDefinition(name: 'Gila', slot: BodySlot.tail, axieClass: AxieClass.reptile, candidateSlugs: ['tail-gila']),
  PartDefinition(name: 'Grass Snake', slot: BodySlot.tail, axieClass: AxieClass.reptile, candidateSlugs: ['tail-grass-snake']),

  // ==========================================
  // EYES (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Eyes (6)
  PartDefinition(name: 'Puppy', slot: BodySlot.eyes, axieClass: AxieClass.beast, candidateSlugs: ['eyes-puppy']),
  PartDefinition(name: 'Calico', slot: BodySlot.eyes, axieClass: AxieClass.beast, candidateSlugs: ['eyes-calico', 'eyes-calico-zee']),
  PartDefinition(name: 'Little Peas', slot: BodySlot.eyes, axieClass: AxieClass.beast, candidateSlugs: ['eyes-little-peas']),
  PartDefinition(name: 'Chubby', slot: BodySlot.eyes, axieClass: AxieClass.beast, candidateSlugs: ['eyes-chubby']),
  PartDefinition(name: 'Zeal', slot: BodySlot.eyes, axieClass: AxieClass.beast, candidateSlugs: ['eyes-zeal', 'eyes-chubby', 'eyes-zeek']),
  PartDefinition(name: 'Snowflakes', slot: BodySlot.eyes, axieClass: AxieClass.beast, candidateSlugs: ['eyes-snowflakes']),

  // Aquatic Eyes (6)
  PartDefinition(name: 'Sleepless', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, candidateSlugs: ['eyes-sleepless']),
  PartDefinition(name: 'Clear', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, candidateSlugs: ['eyes-clear']),
  PartDefinition(name: 'Gero', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, candidateSlugs: ['eyes-gero']),
  PartDefinition(name: 'Telescope', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, candidateSlugs: ['eyes-telescope', 'eyes-telescopes']),
  PartDefinition(name: 'Insomnia', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, candidateSlugs: ['eyes-insomnia']),
  PartDefinition(name: 'Gero / Clear', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, candidateSlugs: ['eyes-clear', 'eyes-gero', 'eyes-blosson']),

  // Plant Eyes (6)
  PartDefinition(name: 'Papi', slot: BodySlot.eyes, axieClass: AxieClass.plant, candidateSlugs: ['eyes-papi']),
  PartDefinition(name: 'Blossom', slot: BodySlot.eyes, axieClass: AxieClass.plant, candidateSlugs: ['eyes-blossom']),
  PartDefinition(name: 'Cucumber Slice', slot: BodySlot.eyes, axieClass: AxieClass.plant, candidateSlugs: ['eyes-cucumber-slice']),
  PartDefinition(name: 'Confused', slot: BodySlot.eyes, axieClass: AxieClass.plant, candidateSlugs: ['eyes-confused']),
  PartDefinition(name: 'Confused / Papi', slot: BodySlot.eyes, axieClass: AxieClass.plant, candidateSlugs: ['eyes-confused', 'eyes-papi', 'eyes-mistletoe']),
  PartDefinition(name: 'Dreamy Papi', slot: BodySlot.eyes, axieClass: AxieClass.plant, candidateSlugs: ['eyes-dreamy-papi']),

  // Bird Eyes (6)
  PartDefinition(name: 'Mavis', slot: BodySlot.eyes, axieClass: AxieClass.bird, candidateSlugs: ['eyes-mavis']),
  PartDefinition(name: 'Lucas', slot: BodySlot.eyes, axieClass: AxieClass.bird, candidateSlugs: ['eyes-lucas']),
  PartDefinition(name: 'Robin', slot: BodySlot.eyes, axieClass: AxieClass.bird, candidateSlugs: ['eyes-robin']),
  PartDefinition(name: 'Little Owl', slot: BodySlot.eyes, axieClass: AxieClass.bird, candidateSlugs: ['eyes-little-owl']),
  PartDefinition(name: 'Sky Mavis', slot: BodySlot.eyes, axieClass: AxieClass.bird, candidateSlugs: ['eyes-sky-mavis']),
  PartDefinition(name: 'Crimson Gecko', slot: BodySlot.eyes, axieClass: AxieClass.bird, candidateSlugs: ['eyes-crimson-gecko']),

  // Bug Eyes (6)
  PartDefinition(name: 'Bookworm', slot: BodySlot.eyes, axieClass: AxieClass.bug, candidateSlugs: ['eyes-bookworm']),
  PartDefinition(name: 'Neo', slot: BodySlot.eyes, axieClass: AxieClass.bug, candidateSlugs: ['eyes-neo']),
  PartDefinition(name: 'Nerdy', slot: BodySlot.eyes, axieClass: AxieClass.bug, candidateSlugs: ['eyes-nerdy']),
  PartDefinition(name: 'Kotaro', slot: BodySlot.eyes, axieClass: AxieClass.bug, candidateSlugs: ['eyes-kotaro']),
  PartDefinition(name: 'Bookworm / Neo', slot: BodySlot.eyes, axieClass: AxieClass.bug, candidateSlugs: ['eyes-neo', 'eyes-bookworm', 'eyes-geisha']),
  PartDefinition(name: 'Nerdy / Dente', slot: BodySlot.eyes, axieClass: AxieClass.bug, candidateSlugs: ['eyes-nerdy', 'eyes-kotaro', 'eyes-dente']),

  // Reptile Eyes (6)
  PartDefinition(name: 'Tricky', slot: BodySlot.eyes, axieClass: AxieClass.reptile, candidateSlugs: ['eyes-tricky']),
  PartDefinition(name: 'Topaz', slot: BodySlot.eyes, axieClass: AxieClass.reptile, candidateSlugs: ['eyes-topaz']),
  PartDefinition(name: 'Scar', slot: BodySlot.eyes, axieClass: AxieClass.reptile, candidateSlugs: ['eyes-scar']),
  PartDefinition(name: 'Kabuki', slot: BodySlot.eyes, axieClass: AxieClass.reptile, candidateSlugs: ['eyes-kabuki']),
  PartDefinition(name: 'Kabuki / Tricky', slot: BodySlot.eyes, axieClass: AxieClass.reptile, candidateSlugs: ['eyes-tricky', 'eyes-kabuki', 'eyes-crimson-tooth']),
  PartDefinition(name: 'Topaz / Scar', slot: BodySlot.eyes, axieClass: AxieClass.reptile, candidateSlugs: ['eyes-topaz', 'eyes-scar', 'eyes-scarlet-frog']),

  // ==========================================
  // EARS (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Ears (6)
  PartDefinition(name: 'Nut Cracker', slot: BodySlot.ears, axieClass: AxieClass.beast, candidateSlugs: ['ears-nut-cracker']),
  PartDefinition(name: 'Nyan', slot: BodySlot.ears, axieClass: AxieClass.beast, candidateSlugs: ['ears-nyan']),
  PartDefinition(name: 'Pointy Nyan', slot: BodySlot.ears, axieClass: AxieClass.beast, candidateSlugs: ['ears-pointy-nyan']),
  PartDefinition(name: 'Innocent Lamb', slot: BodySlot.ears, axieClass: AxieClass.beast, candidateSlugs: ['ears-innocent-lamb']),
  PartDefinition(name: 'Belieber', slot: BodySlot.ears, axieClass: AxieClass.beast, candidateSlugs: ['ears-belieber']),
  PartDefinition(name: 'Puppy', slot: BodySlot.ears, axieClass: AxieClass.beast, candidateSlugs: ['ears-puppy']),

  // Aquatic Ears (6)
  PartDefinition(name: 'Nimo', slot: BodySlot.ears, axieClass: AxieClass.aquatic, candidateSlugs: ['ears-nimo']),
  PartDefinition(name: 'Tiny Fan', slot: BodySlot.ears, axieClass: AxieClass.aquatic, candidateSlugs: ['ears-tiny-fan']),
  PartDefinition(name: 'Bubblemaker', slot: BodySlot.ears, axieClass: AxieClass.aquatic, candidateSlugs: ['ears-bubblemaker']),
  PartDefinition(name: 'Gill', slot: BodySlot.ears, axieClass: AxieClass.aquatic, candidateSlugs: ['ears-gill']),
  PartDefinition(name: 'Sea Bream / Seaslug', slot: BodySlot.ears, axieClass: AxieClass.aquatic, candidateSlugs: ['ears-seaslug', 'ears-sea-bream', 'ears-seabream']),
  PartDefinition(name: 'Inkling', slot: BodySlot.ears, axieClass: AxieClass.aquatic, candidateSlugs: ['ears-inkling']),

  // Plant Ears (6)
  PartDefinition(name: 'Rosa / Hollow', slot: BodySlot.ears, axieClass: AxieClass.plant, candidateSlugs: ['ears-hollow', 'ears-rosa', 'ears-serious']),
  PartDefinition(name: 'Sakura', slot: BodySlot.ears, axieClass: AxieClass.plant, candidateSlugs: ['ears-sakura']),
  PartDefinition(name: 'Leaf', slot: BodySlot.ears, axieClass: AxieClass.plant, candidateSlugs: ['ears-lotus', 'ears-leafy', 'ears-leaf', 'ears-leaves']),
  PartDefinition(name: 'Clover', slot: BodySlot.ears, axieClass: AxieClass.plant, candidateSlugs: ['ears-clover']),
  PartDefinition(name: 'Rosa', slot: BodySlot.ears, axieClass: AxieClass.plant, candidateSlugs: ['ears-rosa']),
  PartDefinition(name: 'Hollow', slot: BodySlot.ears, axieClass: AxieClass.plant, candidateSlugs: ['ears-hollow']),

  // Bird Ears (6)
  PartDefinition(name: 'Pink Cheek', slot: BodySlot.ears, axieClass: AxieClass.bird, candidateSlugs: ['ears-pink-cheek']),
  PartDefinition(name: 'Early Bird', slot: BodySlot.ears, axieClass: AxieClass.bird, candidateSlugs: ['ears-early-bird']),
  PartDefinition(name: 'Owl', slot: BodySlot.ears, axieClass: AxieClass.bird, candidateSlugs: ['ears-owl']),
  PartDefinition(name: 'Curved Spine', slot: BodySlot.ears, axieClass: AxieClass.bird, candidateSlugs: ['ears-curved-spine']),
  PartDefinition(name: 'Peace Maker', slot: BodySlot.ears, axieClass: AxieClass.bird, candidateSlugs: ['ears-peace-maker']),
  PartDefinition(name: 'Risky Bird', slot: BodySlot.ears, axieClass: AxieClass.bird, candidateSlugs: ['ears-risky-bird']),

  // Bug Ears (6)
  PartDefinition(name: 'Beetle Spike', slot: BodySlot.ears, axieClass: AxieClass.bug, candidateSlugs: ['ears-beetle-spike']),
  PartDefinition(name: 'Ear Breathing', slot: BodySlot.ears, axieClass: AxieClass.bug, candidateSlugs: ['ears-ear-breathing']),
  PartDefinition(name: 'Larva', slot: BodySlot.ears, axieClass: AxieClass.bug, candidateSlugs: ['ears-larva']),
  PartDefinition(name: 'Tassels', slot: BodySlot.ears, axieClass: AxieClass.bug, candidateSlugs: ['ears-tassels']),
  PartDefinition(name: 'Caterpillar', slot: BodySlot.ears, axieClass: AxieClass.bug, candidateSlugs: ['ears-earwing', 'ears-leaf-bug', 'ears-caterpillar', 'ears-caterpillars']),
  PartDefinition(name: 'Vector', slot: BodySlot.ears, axieClass: AxieClass.bug, candidateSlugs: ['ears-vector']),

  // Reptile Ears (6)
  PartDefinition(name: 'Pogona', slot: BodySlot.ears, axieClass: AxieClass.reptile, candidateSlugs: ['ears-pogona']),
  PartDefinition(name: 'Small Frill / Swirl / Friezard', slot: BodySlot.ears, axieClass: AxieClass.reptile, candidateSlugs: ['ears-friezard', 'ears-small-frill', 'ears-swirl', 'ears-frizzy']),
  PartDefinition(name: 'Small Frill', slot: BodySlot.ears, axieClass: AxieClass.reptile, candidateSlugs: ['ears-small-frill']),
  PartDefinition(name: 'Curved Spine', slot: BodySlot.ears, axieClass: AxieClass.reptile, candidateSlugs: ['ears-curved-spine']),
  PartDefinition(name: 'Side Bar', slot: BodySlot.ears, axieClass: AxieClass.reptile, candidateSlugs: ['ears-sidebarb', 'ears-side-bar', 'ears-sidebar']),
  PartDefinition(name: 'Swirl', slot: BodySlot.ears, axieClass: AxieClass.reptile, candidateSlugs: ['ears-swirl']),
];

/// Resolves the candidate slug with count > 0, falling back to first candidate.
Future<ResolvedPart> resolvePartCount({
  required PartDefinition definition,
  required AxieGraphQLClient client,
}) async {
  for (final slug in definition.candidateSlugs) {
    stdout.write('  Evaluating slug "$slug"... ');
    final count = await client.fetchPartCount(slug);
    stdout.writeln('$count');
    if (count > 0) {
      return ResolvedPart(
        definition: definition,
        resolvedSlug: slug,
        count: count,
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 75));
  }

  // Fallback to first candidate slug with count 0
  final fallbackSlug = definition.candidateSlugs.first;
  stdout.writeln('  [FALLBACK] Zero count across candidates. Defaulting to "$fallbackSlug" (0).');
  return ResolvedPart(
    definition: definition,
    resolvedSlug: fallbackSlug,
    count: 0,
  );
}

/// Helper to generate the exact 288 mouth-tail permutation records with typing and classification.
List<PermutationRecord> generatePermutations({
  required Map<AxieClass, List<String>> mouthsByClass,
  required Map<AxieClass, List<String>> tailsByClass,
}) {
  final List<PermutationRecord> permutations = [];

  void addPermutations({
    required AxieClass mouthClass,
    required AxieClass tailClass,
    required String type,
    required String classification,
  }) {
    final mouths = mouthsByClass[mouthClass] ?? [];
    final tails = tailsByClass[tailClass] ?? [];
    for (final m in mouths) {
      for (final t in tails) {
        permutations.add(PermutationRecord(
          mouthSlug: m,
          tailSlug: t,
          type: type,
          classification: classification,
        ));
      }
    }
  }

  // 1. Pure Lineages (144): 6 classes * (4 mouths * 6 tails) = 144
  for (final cls in AxieClass.values) {
    addPermutations(
      mouthClass: cls,
      tailClass: cls,
      type: 'Pure',
      classification: cls.label,
    );
  }

  // 2. Mech (48): Bug Mouth x Beast Tail (24) + Beast Mouth x Bug Tail (24)
  addPermutations(
    mouthClass: AxieClass.bug,
    tailClass: AxieClass.beast,
    type: 'Mix',
    classification: 'Mech',
  );
  addPermutations(
    mouthClass: AxieClass.beast,
    tailClass: AxieClass.bug,
    type: 'Mix',
    classification: 'Mech',
  );

  // 3. Dusk (48): Reptile Mouth x Aquatic Tail (24) + Aquatic Mouth x Reptile Tail (24)
  addPermutations(
    mouthClass: AxieClass.reptile,
    tailClass: AxieClass.aquatic,
    type: 'Mix',
    classification: 'Dusk',
  );
  addPermutations(
    mouthClass: AxieClass.aquatic,
    tailClass: AxieClass.reptile,
    type: 'Mix',
    classification: 'Dusk',
  );

  // 4. Dawn (48): Plant Mouth x Bird Tail (24) + Bird Mouth x Plant Tail (24)
  addPermutations(
    mouthClass: AxieClass.plant,
    tailClass: AxieClass.bird,
    type: 'Mix',
    classification: 'Dawn',
  );
  addPermutations(
    mouthClass: AxieClass.bird,
    tailClass: AxieClass.plant,
    type: 'Mix',
    classification: 'Dawn',
  );

  return permutations;
}

/// Resolves the Sky Mavis API Key from environment or secrets.env.
String resolveApiKey() {
  final envKey = Platform.environment['SKY_MAVIS_API_KEY'];
  if (envKey != null && envKey.trim().isNotEmpty) {
    return envKey.trim();
  }

  final candidates = [
    File('secrets.env'),
    File('../secrets.env'),
    File('C:/NeuroField/active_projects/lunacian_card_wars/secrets.env'),
  ];

  for (final file in candidates) {
    if (file.existsSync()) {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('SKY_MAVIS_API_KEY=')) {
          final key = trimmed.substring('SKY_MAVIS_API_KEY='.length).trim();
          if (key.isNotEmpty) return key;
        }
      }
    }
  }

  return '';
}

/// GraphQL client with rate limiting and exponential backoff retry logic.
class AxieGraphQLClient {
  static const String endpoint =
      'https://api-gateway.skymavis.com/graphql/axie-marketplace';

  final String apiKey;
  final http.Client _client = http.Client();

  AxieGraphQLClient({required this.apiKey});

  static const String partQuery = r'''
query GetPartCount($partId: String!) {
  axies(criteria: { parts: [$partId] }, size: 0) {
    total
  }
}
''';

  static const String permutationQuery = r'''
query GetPermutationCount($partA: String!, $partB: String!) {
  axies(criteria: { parts: [$partA, $partB] }, size: 0) {
    total
  }
}
''';

  Future<int> fetchPartCount(String partId) async {
    return _executeQuery(
      query: partQuery,
      variables: {'partId': partId},
      context: 'Part: $partId',
    );
  }

  Future<int> fetchPermutationCount(String partA, String partB) async {
    return _executeQuery(
      query: permutationQuery,
      variables: {'partA': partA, 'partB': partB},
      context: 'Permutation: ${partA}__$partB',
    );
  }

  Future<int> _executeQuery({
    required String query,
    required Map<String, dynamic> variables,
    required String context,
  }) async {
    const int maxRetries = 5;
    int attempt = 0;
    int delayMs = 1000;

    while (true) {
      attempt++;
      try {
        final response = await _client.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': apiKey,
          },
          body: jsonEncode({
            'query': query,
            'variables': variables,
          }),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body.containsKey('errors')) {
            final errors = body['errors'];
            stderr.writeln('GraphQL error on $context: $errors');
            return 0;
          }
          final data = body['data'];
          if (data != null && data['axies'] != null && data['axies']['total'] != null) {
            return (data['axies']['total'] as num).toInt();
          }
          return 0;
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempt >= maxRetries) {
            stderr.writeln('HTTP ${response.statusCode} on $context after $maxRetries attempts. Aborting.');
            return 0;
          }
          stderr.writeln('HTTP ${response.statusCode} on $context. Retrying in ${delayMs}ms (attempt $attempt)...');
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        } else {
          stderr.writeln('HTTP ${response.statusCode} on $context: ${response.body}');
          return 0;
        }
      } catch (e) {
        if (attempt >= maxRetries) {
          stderr.writeln('Network error on $context after $maxRetries attempts: $e');
          return 0;
        }
        stderr.writeln('Network error on $context: $e. Retrying in ${delayMs}ms (attempt $attempt)...');
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
      }
    }
  }

  void close() {
    _client.close();
  }
}

Future<void> main(List<String> args) async {
  stdout.writeln('====================================================');
  stdout.writeln('Axie Infinity Demographic Census Extractor');
  stdout.writeln('Pure Domain CLI Script — Cycle 11.9 (Refactor)');
  stdout.writeln('====================================================');

  final apiKey = resolveApiKey();
  if (apiKey.isEmpty) {
    stderr.writeln('ERROR: SKY_MAVIS_API_KEY is not set in environment or secrets.env!');
    exit(1);
  }

  stdout.writeln('API Key loaded successfully.');

  final client = AxieGraphQLClient(apiKey: apiKey);

  final dataDir = Directory('assets/data');
  if (!dataDir.existsSync()) {
    dataDir.createSync(recursive: true);
  }

  final partStatsFile = File('assets/data/axie_part_stats_and_floops.csv');
  final permutationStatsFile = File('assets/data/mouth_tail_permutation_floops.csv');

  // Phase 1: Query 204 Parts with Dynamic Candidate Resolution
  stdout.writeln('\n[Phase 1] Resolving and querying 204 anatomical body parts...');
  final List<String> partCsvLines = [
    'Part_Name,Slot,Class,GraphQL_ID,Axie_Amount',
  ];

  final Map<AxieClass, List<String>> resolvedMouthsByClass = {};
  final Map<AxieClass, List<String>> resolvedTailsByClass = {};

  int partIndex = 0;
  for (final partDef in kAxiePartsCatalog) {
    partIndex++;
    stdout.writeln('[$partIndex/204] Resolving ${partDef.name} (${partDef.slot.label}, ${partDef.axieClass.label})...');
    final resolved = await resolvePartCount(
      definition: partDef,
      client: client,
    );
    stdout.writeln('  -> Final Resolved: ${resolved.resolvedSlug} = ${resolved.count}');

    partCsvLines.add(
      '${resolved.definition.name},${resolved.definition.slot.label},${resolved.definition.axieClass.label},${resolved.resolvedSlug},${resolved.count}',
    );

    if (resolved.definition.slot == BodySlot.mouth) {
      resolvedMouthsByClass
          .putIfAbsent(resolved.definition.axieClass, () => [])
          .add(resolved.resolvedSlug);
    } else if (resolved.definition.slot == BodySlot.tail) {
      resolvedTailsByClass
          .putIfAbsent(resolved.definition.axieClass, () => [])
          .add(resolved.resolvedSlug);
    }

    await Future<void>.delayed(const Duration(milliseconds: 75));
  }

  partStatsFile.writeAsStringSync('${partCsvLines.join('\n')}\n');
  stdout.writeln('✓ Successfully saved 204 parts to ${partStatsFile.path} (${partCsvLines.length} lines)');

  // Phase 2: Query 288 Mouth-Tail Permutations with Metadata
  stdout.writeln('\n[Phase 2] Querying 288 mouth-tail genetic permutations...');
  final permutations = generatePermutations(
    mouthsByClass: resolvedMouthsByClass,
    tailsByClass: resolvedTailsByClass,
  );
  assert(permutations.length == 288, 'Permutation count must equal exactly 288!');

  final List<String> permCsvLines = [
    'permutation_mouth_tail,Axie_amount,Permutation_Type,Permutation_class',
  ];

  int permIndex = 0;
  for (final record in permutations) {
    permIndex++;
    final mouthId = record.mouthSlug;
    final tailId = record.tailSlug;
    final pairKey = record.key;

    stdout.write('[$permIndex/288] Fetching $pairKey (${record.type} / ${record.classification})... ');
    final count = await client.fetchPermutationCount(mouthId, tailId);
    stdout.writeln('$count');

    permCsvLines.add('$pairKey,$count,${record.type},${record.classification}');
    await Future<void>.delayed(const Duration(milliseconds: 75));
  }

  permutationStatsFile.writeAsStringSync('${permCsvLines.join('\n')}\n');
  stdout.writeln('✓ Successfully saved 288 permutations to ${permutationStatsFile.path} (${permCsvLines.length} lines)');

  client.close();
  stdout.writeln('\n====================================================');
  stdout.writeln('CENSUS REFACTOR EXTRACTION COMPLETE!');
  stdout.writeln('====================================================');
}
