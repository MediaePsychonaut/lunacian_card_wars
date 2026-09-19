// ===============================================================================
// [MODULE_NAME]: fetch_axie_census.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Tool / Census
// [INTENT]: Pure Dart CLI script querying Sky Mavis GraphQL API to extract on-chain minted population census for all 204 anatomical parts and 288 mouth-tail genetic permutations across 6 classes.
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

/// Anatomical part metadata model.
class AxiePart {
  final String name;
  final BodySlot slot;
  final AxieClass axieClass;
  final String graphQLId;

  const AxiePart({
    required this.name,
    required this.slot,
    required this.axieClass,
    required this.graphQLId,
  });
}

/// Canonical catalog of all 204 physical anatomical parts in Axie Infinity.
/// Strictly aligned to DIR_LCW_GRAPHQL_CENSUS_6_PARTS_AND_PERMUTATIONS_CYCLE_11_9.
const List<AxiePart> kAxiePartsCatalog = [
  // ==========================================
  // HORNS (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Horns (6)
  AxiePart(name: 'Little Branch', slot: BodySlot.horn, axieClass: AxieClass.beast, graphQLId: 'horn-little-branch'),
  AxiePart(name: 'Imp', slot: BodySlot.horn, axieClass: AxieClass.beast, graphQLId: 'horn-imp'),
  AxiePart(name: 'Merry', slot: BodySlot.horn, axieClass: AxieClass.beast, graphQLId: 'horn-merry'),
  AxiePart(name: 'Pocky', slot: BodySlot.horn, axieClass: AxieClass.beast, graphQLId: 'horn-pocky'),
  AxiePart(name: 'Dual Blade', slot: BodySlot.horn, axieClass: AxieClass.beast, graphQLId: 'horn-dual-blade'),
  AxiePart(name: 'Arco', slot: BodySlot.horn, axieClass: AxieClass.beast, graphQLId: 'horn-arco'),

  // Aquatic Horns (6)
  AxiePart(name: 'Babylonia', slot: BodySlot.horn, axieClass: AxieClass.aquatic, graphQLId: 'horn-babylonia'),
  AxiePart(name: 'Teal Shell', slot: BodySlot.horn, axieClass: AxieClass.aquatic, graphQLId: 'horn-teal-shell'),
  AxiePart(name: 'Clamshell', slot: BodySlot.horn, axieClass: AxieClass.aquatic, graphQLId: 'horn-clamshell'),
  AxiePart(name: 'Anemone', slot: BodySlot.horn, axieClass: AxieClass.aquatic, graphQLId: 'horn-anemone'),
  AxiePart(name: 'Oranda', slot: BodySlot.horn, axieClass: AxieClass.aquatic, graphQLId: 'horn-oranda'),
  AxiePart(name: 'Shoal Star', slot: BodySlot.horn, axieClass: AxieClass.aquatic, graphQLId: 'horn-shoal-star'),

  // Plant Horns (6)
  AxiePart(name: 'Bamboo', slot: BodySlot.horn, axieClass: AxieClass.plant, graphQLId: 'horn-bamboo'),
  AxiePart(name: 'Beech', slot: BodySlot.horn, axieClass: AxieClass.plant, graphQLId: 'horn-beech'),
  AxiePart(name: 'Rose Bud', slot: BodySlot.horn, axieClass: AxieClass.plant, graphQLId: 'horn-rose-bud'),
  AxiePart(name: 'Strawberry Shortcake', slot: BodySlot.horn, axieClass: AxieClass.plant, graphQLId: 'horn-strawberry-shortcake'),
  AxiePart(name: 'Cactus', slot: BodySlot.horn, axieClass: AxieClass.plant, graphQLId: 'horn-cactus'),
  AxiePart(name: 'Watermelon', slot: BodySlot.horn, axieClass: AxieClass.plant, graphQLId: 'horn-watermelon'),

  // Bird Horns (6)
  AxiePart(name: 'Eggshell', slot: BodySlot.horn, axieClass: AxieClass.bird, graphQLId: 'horn-eggshell'),
  AxiePart(name: 'Cuckoo', slot: BodySlot.horn, axieClass: AxieClass.bird, graphQLId: 'horn-cuckoo'),
  AxiePart(name: 'Trump', slot: BodySlot.horn, axieClass: AxieClass.bird, graphQLId: 'horn-trump'),
  AxiePart(name: 'Kestrel', slot: BodySlot.horn, axieClass: AxieClass.bird, graphQLId: 'horn-kestrel'),
  AxiePart(name: 'Wing Horn', slot: BodySlot.horn, axieClass: AxieClass.bird, graphQLId: 'horn-wing-horn'),
  AxiePart(name: 'Feather Spear', slot: BodySlot.horn, axieClass: AxieClass.bird, graphQLId: 'horn-feather-spear'),

  // Bug Horns (6)
  AxiePart(name: 'Vall Ein', slot: BodySlot.horn, axieClass: AxieClass.bug, graphQLId: 'horn-vall-ein'),
  AxiePart(name: 'Antenna', slot: BodySlot.horn, axieClass: AxieClass.bug, graphQLId: 'horn-antenna'),
  AxiePart(name: 'Caterpillar', slot: BodySlot.horn, axieClass: AxieClass.bug, graphQLId: 'horn-caterpillar'),
  AxiePart(name: 'Pliers', slot: BodySlot.horn, axieClass: AxieClass.bug, graphQLId: 'horn-pliers'),
  AxiePart(name: 'Parasite', slot: BodySlot.horn, axieClass: AxieClass.bug, graphQLId: 'horn-parasite'),
  AxiePart(name: 'Leaf Bug', slot: BodySlot.horn, axieClass: AxieClass.bug, graphQLId: 'horn-leaf-bug'),

  // Reptile Horns (6)
  AxiePart(name: 'Unko', slot: BodySlot.horn, axieClass: AxieClass.reptile, graphQLId: 'horn-unko'),
  AxiePart(name: 'Scaly Spear', slot: BodySlot.horn, axieClass: AxieClass.reptile, graphQLId: 'horn-scaly-spear'),
  AxiePart(name: 'Cerastes', slot: BodySlot.horn, axieClass: AxieClass.reptile, graphQLId: 'horn-cerastes'),
  AxiePart(name: 'Scaly Spoon', slot: BodySlot.horn, axieClass: AxieClass.reptile, graphQLId: 'horn-scaly-spoon'),
  AxiePart(name: 'Incisor', slot: BodySlot.horn, axieClass: AxieClass.reptile, graphQLId: 'horn-incisor'),
  AxiePart(name: 'Bumpy', slot: BodySlot.horn, axieClass: AxieClass.reptile, graphQLId: 'horn-bumpy'),

  // ==========================================
  // BACKS (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Backs (6)
  AxiePart(name: 'Ronin', slot: BodySlot.back, axieClass: AxieClass.beast, graphQLId: 'back-ronin'),
  AxiePart(name: 'Hero', slot: BodySlot.back, axieClass: AxieClass.beast, graphQLId: 'back-hero'),
  AxiePart(name: 'Jaguar', slot: BodySlot.back, axieClass: AxieClass.beast, graphQLId: 'back-jaguar'),
  AxiePart(name: 'Risky Beast', slot: BodySlot.back, axieClass: AxieClass.beast, graphQLId: 'back-risky-beast'),
  AxiePart(name: 'Timber', slot: BodySlot.back, axieClass: AxieClass.beast, graphQLId: 'back-timber'),
  AxiePart(name: 'Furball', slot: BodySlot.back, axieClass: AxieClass.beast, graphQLId: 'back-furball'),

  // Aquatic Backs (6)
  AxiePart(name: 'Hermit', slot: BodySlot.back, axieClass: AxieClass.aquatic, graphQLId: 'back-hermit'),
  AxiePart(name: 'Blue Moon', slot: BodySlot.back, axieClass: AxieClass.aquatic, graphQLId: 'back-blue-moon'),
  AxiePart(name: 'Goldfish', slot: BodySlot.back, axieClass: AxieClass.aquatic, graphQLId: 'back-goldfish'),
  AxiePart(name: 'Sponge', slot: BodySlot.back, axieClass: AxieClass.aquatic, graphQLId: 'back-sponge'),
  AxiePart(name: 'Anemone', slot: BodySlot.back, axieClass: AxieClass.aquatic, graphQLId: 'back-anemone'),
  AxiePart(name: 'Perch', slot: BodySlot.back, axieClass: AxieClass.aquatic, graphQLId: 'back-perch'),

  // Plant Backs (6)
  AxiePart(name: 'Turnip', slot: BodySlot.back, axieClass: AxieClass.plant, graphQLId: 'back-turnip'),
  AxiePart(name: 'Shiitake', slot: BodySlot.back, axieClass: AxieClass.plant, graphQLId: 'back-shiitake'),
  AxiePart(name: 'Bidens', slot: BodySlot.back, axieClass: AxieClass.plant, graphQLId: 'back-bidens'),
  AxiePart(name: 'Watering Can', slot: BodySlot.back, axieClass: AxieClass.plant, graphQLId: 'back-watering-can'),
  AxiePart(name: 'Mint', slot: BodySlot.back, axieClass: AxieClass.plant, graphQLId: 'back-mint'),
  AxiePart(name: 'Pumpkin', slot: BodySlot.back, axieClass: AxieClass.plant, graphQLId: 'back-pumpkin'),

  // Bird Backs (6)
  AxiePart(name: 'Pigeon Post', slot: BodySlot.back, axieClass: AxieClass.bird, graphQLId: 'back-pigeon-post'),
  AxiePart(name: 'Raven', slot: BodySlot.back, axieClass: AxieClass.bird, graphQLId: 'back-raven'),
  AxiePart(name: 'Cupid', slot: BodySlot.back, axieClass: AxieClass.bird, graphQLId: 'back-cupid'),
  AxiePart(name: 'Kingfisher', slot: BodySlot.back, axieClass: AxieClass.bird, graphQLId: 'back-kingfisher'),
  AxiePart(name: 'Tri Feather', slot: BodySlot.back, axieClass: AxieClass.bird, graphQLId: 'back-tri-feather'),
  AxiePart(name: 'Balloon', slot: BodySlot.back, axieClass: AxieClass.bird, graphQLId: 'back-balloon'),

  // Bug Backs (6)
  AxiePart(name: 'Snail Shell', slot: BodySlot.back, axieClass: AxieClass.bug, graphQLId: 'back-snail-shell'),
  AxiePart(name: 'Garish Worm', slot: BodySlot.back, axieClass: AxieClass.bug, graphQLId: 'back-garish-worm'),
  AxiePart(name: 'Buzz Buzz', slot: BodySlot.back, axieClass: AxieClass.bug, graphQLId: 'back-buzz-buzz'),
  AxiePart(name: 'Sandal', slot: BodySlot.back, axieClass: AxieClass.bug, graphQLId: 'back-sandal'),
  AxiePart(name: 'Scarab', slot: BodySlot.back, axieClass: AxieClass.bug, graphQLId: 'back-scarab'),
  AxiePart(name: 'Spiky Wing', slot: BodySlot.back, axieClass: AxieClass.bug, graphQLId: 'back-spiky-wing'),

  // Reptile Backs (6)
  AxiePart(name: 'Bone Sail', slot: BodySlot.back, axieClass: AxieClass.reptile, graphQLId: 'back-bone-sail'),
  AxiePart(name: 'Tri Spikes', slot: BodySlot.back, axieClass: AxieClass.reptile, graphQLId: 'back-tri-spikes'),
  AxiePart(name: 'Green Thorns', slot: BodySlot.back, axieClass: AxieClass.reptile, graphQLId: 'back-green-thorns'),
  AxiePart(name: 'Indian Star', slot: BodySlot.back, axieClass: AxieClass.reptile, graphQLId: 'back-indian-star'),
  AxiePart(name: 'Red Ear', slot: BodySlot.back, axieClass: AxieClass.reptile, graphQLId: 'back-red-ear'),
  AxiePart(name: 'Croc', slot: BodySlot.back, axieClass: AxieClass.reptile, graphQLId: 'back-croc'),

  // ==========================================
  // MOUTHS (24 parts: 4 per class * 6 classes)
  // ==========================================
  // Beast Mouths (4)
  AxiePart(name: 'Nutcracker', slot: BodySlot.mouth, axieClass: AxieClass.beast, graphQLId: 'mouth-nut-cracker'),
  AxiePart(name: 'Axie Kiss', slot: BodySlot.mouth, axieClass: AxieClass.beast, graphQLId: 'mouth-axie-kiss'),
  AxiePart(name: 'Goda', slot: BodySlot.mouth, axieClass: AxieClass.beast, graphQLId: 'mouth-goda'),
  AxiePart(name: 'Confident', slot: BodySlot.mouth, axieClass: AxieClass.beast, graphQLId: 'mouth-confident'),

  // Aquatic Mouths (4)
  AxiePart(name: 'Lam', slot: BodySlot.mouth, axieClass: AxieClass.aquatic, graphQLId: 'mouth-lam'),
  AxiePart(name: 'Risky Fish', slot: BodySlot.mouth, axieClass: AxieClass.aquatic, graphQLId: 'mouth-risky-fish'),
  AxiePart(name: 'Piranha', slot: BodySlot.mouth, axieClass: AxieClass.aquatic, graphQLId: 'mouth-piranha'),
  AxiePart(name: 'Catfish', slot: BodySlot.mouth, axieClass: AxieClass.aquatic, graphQLId: 'mouth-catfish'),

  // Plant Mouths (4)
  AxiePart(name: 'Serious', slot: BodySlot.mouth, axieClass: AxieClass.plant, graphQLId: 'mouth-serious'),
  AxiePart(name: 'Zigzag', slot: BodySlot.mouth, axieClass: AxieClass.plant, graphQLId: 'mouth-zigzag'),
  AxiePart(name: 'Herbivore', slot: BodySlot.mouth, axieClass: AxieClass.plant, graphQLId: 'mouth-herbivore'),
  AxiePart(name: 'Silence Whisper', slot: BodySlot.mouth, axieClass: AxieClass.plant, graphQLId: 'mouth-silence-whisper'),

  // Bird Mouths (4)
  AxiePart(name: 'Doubletalk', slot: BodySlot.mouth, axieClass: AxieClass.bird, graphQLId: 'mouth-doubletalk'),
  AxiePart(name: 'Peace Maker', slot: BodySlot.mouth, axieClass: AxieClass.bird, graphQLId: 'mouth-peace-maker'),
  AxiePart(name: 'Little Owl', slot: BodySlot.mouth, axieClass: AxieClass.bird, graphQLId: 'mouth-little-owl'),
  AxiePart(name: 'Hungry Bird', slot: BodySlot.mouth, axieClass: AxieClass.bird, graphQLId: 'mouth-hungry-bird'),

  // Bug Mouths (4)
  AxiePart(name: 'Mosquito', slot: BodySlot.mouth, axieClass: AxieClass.bug, graphQLId: 'mouth-mosquito'),
  AxiePart(name: 'Cute Bunny', slot: BodySlot.mouth, axieClass: AxieClass.bug, graphQLId: 'mouth-cute-bunny'),
  AxiePart(name: 'Square Teeth', slot: BodySlot.mouth, axieClass: AxieClass.bug, graphQLId: 'mouth-square-teeth'),
  AxiePart(name: 'Pincer', slot: BodySlot.mouth, axieClass: AxieClass.bug, graphQLId: 'mouth-pincer'),

  // Reptile Mouths (4)
  AxiePart(name: 'Toothless Bite', slot: BodySlot.mouth, axieClass: AxieClass.reptile, graphQLId: 'mouth-toothless-bite'),
  AxiePart(name: 'Kotaro', slot: BodySlot.mouth, axieClass: AxieClass.reptile, graphQLId: 'mouth-kotaro'),
  AxiePart(name: 'Razor Bite', slot: BodySlot.mouth, axieClass: AxieClass.reptile, graphQLId: 'mouth-razor-bite'),
  AxiePart(name: 'Tiny Turtle', slot: BodySlot.mouth, axieClass: AxieClass.reptile, graphQLId: 'mouth-tiny-turtle'),

  // ==========================================
  // TAILS (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Tails (6)
  AxiePart(name: 'Cottontail', slot: BodySlot.tail, axieClass: AxieClass.beast, graphQLId: 'tail-cottontail'),
  AxiePart(name: 'Rice', slot: BodySlot.tail, axieClass: AxieClass.beast, graphQLId: 'tail-rice'),
  AxiePart(name: 'Shiva', slot: BodySlot.tail, axieClass: AxieClass.beast, graphQLId: 'tail-shiva'),
  AxiePart(name: 'Gerbil', slot: BodySlot.tail, axieClass: AxieClass.beast, graphQLId: 'tail-gerbil'),
  AxiePart(name: 'Hare', slot: BodySlot.tail, axieClass: AxieClass.beast, graphQLId: 'tail-hare'),
  AxiePart(name: 'Nutcracker', slot: BodySlot.tail, axieClass: AxieClass.beast, graphQLId: 'tail-nut-cracker'),

  // Aquatic Tails (6)
  AxiePart(name: 'Koi', slot: BodySlot.tail, axieClass: AxieClass.aquatic, graphQLId: 'tail-koi'),
  AxiePart(name: 'Nimo', slot: BodySlot.tail, axieClass: AxieClass.aquatic, graphQLId: 'tail-nimo'),
  AxiePart(name: 'Tadpole', slot: BodySlot.tail, axieClass: AxieClass.aquatic, graphQLId: 'tail-tadpole'),
  AxiePart(name: 'Ranchu', slot: BodySlot.tail, axieClass: AxieClass.aquatic, graphQLId: 'tail-ranchu'),
  AxiePart(name: 'Navaga', slot: BodySlot.tail, axieClass: AxieClass.aquatic, graphQLId: 'tail-navaga'),
  AxiePart(name: 'Shrimp', slot: BodySlot.tail, axieClass: AxieClass.aquatic, graphQLId: 'tail-shrimp'),

  // Plant Tails (6)
  AxiePart(name: 'Carrot', slot: BodySlot.tail, axieClass: AxieClass.plant, graphQLId: 'tail-carrot'),
  AxiePart(name: 'Cattail', slot: BodySlot.tail, axieClass: AxieClass.plant, graphQLId: 'tail-cattail'),
  AxiePart(name: 'Hatsune', slot: BodySlot.tail, axieClass: AxieClass.plant, graphQLId: 'tail-hatsune'),
  AxiePart(name: 'Yam', slot: BodySlot.tail, axieClass: AxieClass.plant, graphQLId: 'tail-yam'),
  AxiePart(name: 'Potato Leaf', slot: BodySlot.tail, axieClass: AxieClass.plant, graphQLId: 'tail-potato-leaf'),
  AxiePart(name: 'Hot Butt', slot: BodySlot.tail, axieClass: AxieClass.plant, graphQLId: 'tail-hot-butt'),

  // Bird Tails (6)
  AxiePart(name: 'Swallow', slot: BodySlot.tail, axieClass: AxieClass.bird, graphQLId: 'tail-swallow'),
  AxiePart(name: 'Feather Fan', slot: BodySlot.tail, axieClass: AxieClass.bird, graphQLId: 'tail-feather-fan'),
  AxiePart(name: 'The Last One', slot: BodySlot.tail, axieClass: AxieClass.bird, graphQLId: 'tail-the-last-one'),
  AxiePart(name: 'Cloud', slot: BodySlot.tail, axieClass: AxieClass.bird, graphQLId: 'tail-cloud'),
  AxiePart(name: 'Granma\'s Fan', slot: BodySlot.tail, axieClass: AxieClass.bird, graphQLId: 'tail-granmas-fan'),
  AxiePart(name: 'Post Fight', slot: BodySlot.tail, axieClass: AxieClass.bird, graphQLId: 'tail-post-fight'),

  // Bug Tails (6)
  AxiePart(name: 'Ant', slot: BodySlot.tail, axieClass: AxieClass.bug, graphQLId: 'tail-ant'),
  AxiePart(name: 'Twin Needle', slot: BodySlot.tail, axieClass: AxieClass.bug, graphQLId: 'tail-twin-needle'),
  AxiePart(name: 'Fish Snack', slot: BodySlot.tail, axieClass: AxieClass.bug, graphQLId: 'tail-fish-snack'),
  AxiePart(name: 'Gravel Ant', slot: BodySlot.tail, axieClass: AxieClass.bug, graphQLId: 'tail-gravel-ant'),
  AxiePart(name: 'Pupae', slot: BodySlot.tail, axieClass: AxieClass.bug, graphQLId: 'tail-pupae'),
  AxiePart(name: 'Thorny Caterpillar', slot: BodySlot.tail, axieClass: AxieClass.bug, graphQLId: 'tail-thorny-caterpillar'),

  // Reptile Tails (6)
  AxiePart(name: 'Wall Gecko', slot: BodySlot.tail, axieClass: AxieClass.reptile, graphQLId: 'tail-wall-gecko'),
  AxiePart(name: 'Iguana', slot: BodySlot.tail, axieClass: AxieClass.reptile, graphQLId: 'tail-iguana'),
  AxiePart(name: 'Tiny Dino', slot: BodySlot.tail, axieClass: AxieClass.reptile, graphQLId: 'tail-tiny-dino'),
  AxiePart(name: 'Snake Jar', slot: BodySlot.tail, axieClass: AxieClass.reptile, graphQLId: 'tail-snake-jar'),
  AxiePart(name: 'Gila', slot: BodySlot.tail, axieClass: AxieClass.reptile, graphQLId: 'tail-gila'),
  AxiePart(name: 'Grass Snake', slot: BodySlot.tail, axieClass: AxieClass.reptile, graphQLId: 'tail-grass-snake'),

  // ==========================================
  // EYES (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Eyes (6)
  AxiePart(name: 'Puppy', slot: BodySlot.eyes, axieClass: AxieClass.beast, graphQLId: 'eyes-puppy'),
  AxiePart(name: 'Calico Zee', slot: BodySlot.eyes, axieClass: AxieClass.beast, graphQLId: 'eyes-calico-zee'),
  AxiePart(name: 'Little Peas', slot: BodySlot.eyes, axieClass: AxieClass.beast, graphQLId: 'eyes-little-peas'),
  AxiePart(name: 'Chubby', slot: BodySlot.eyes, axieClass: AxieClass.beast, graphQLId: 'eyes-chubby'),
  AxiePart(name: 'Zeek', slot: BodySlot.eyes, axieClass: AxieClass.beast, graphQLId: 'eyes-zeek'),
  AxiePart(name: 'Snowflakes', slot: BodySlot.eyes, axieClass: AxieClass.beast, graphQLId: 'eyes-snowflakes'),

  // Aquatic Eyes (6)
  AxiePart(name: 'Sleepless', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, graphQLId: 'eyes-sleepless'),
  AxiePart(name: 'Clear', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, graphQLId: 'eyes-clear'),
  AxiePart(name: 'Gero', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, graphQLId: 'eyes-gero'),
  AxiePart(name: 'Telescopes', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, graphQLId: 'eyes-telescopes'),
  AxiePart(name: 'Insomnia', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, graphQLId: 'eyes-insomnia'),
  AxiePart(name: 'Blosson', slot: BodySlot.eyes, axieClass: AxieClass.aquatic, graphQLId: 'eyes-blosson'),

  // Plant Eyes (6)
  AxiePart(name: 'Papi', slot: BodySlot.eyes, axieClass: AxieClass.plant, graphQLId: 'eyes-papi'),
  AxiePart(name: 'Blossom', slot: BodySlot.eyes, axieClass: AxieClass.plant, graphQLId: 'eyes-blossom'),
  AxiePart(name: 'Cucumber Slice', slot: BodySlot.eyes, axieClass: AxieClass.plant, graphQLId: 'eyes-cucumber-slice'),
  AxiePart(name: 'Confused', slot: BodySlot.eyes, axieClass: AxieClass.plant, graphQLId: 'eyes-confused'),
  AxiePart(name: 'Mistletoe', slot: BodySlot.eyes, axieClass: AxieClass.plant, graphQLId: 'eyes-mistletoe'),
  AxiePart(name: 'Dreamy Papi', slot: BodySlot.eyes, axieClass: AxieClass.plant, graphQLId: 'eyes-dreamy-papi'),

  // Bird Eyes (6)
  AxiePart(name: 'Mavis', slot: BodySlot.eyes, axieClass: AxieClass.bird, graphQLId: 'eyes-mavis'),
  AxiePart(name: 'Lucas', slot: BodySlot.eyes, axieClass: AxieClass.bird, graphQLId: 'eyes-lucas'),
  AxiePart(name: 'Robin', slot: BodySlot.eyes, axieClass: AxieClass.bird, graphQLId: 'eyes-robin'),
  AxiePart(name: 'Little Owl', slot: BodySlot.eyes, axieClass: AxieClass.bird, graphQLId: 'eyes-little-owl'),
  AxiePart(name: 'Sky Mavis', slot: BodySlot.eyes, axieClass: AxieClass.bird, graphQLId: 'eyes-sky-mavis'),
  AxiePart(name: 'Crimson Gecko', slot: BodySlot.eyes, axieClass: AxieClass.bird, graphQLId: 'eyes-crimson-gecko'),

  // Bug Eyes (6)
  AxiePart(name: 'Bookworm', slot: BodySlot.eyes, axieClass: AxieClass.bug, graphQLId: 'eyes-bookworm'),
  AxiePart(name: 'Neo', slot: BodySlot.eyes, axieClass: AxieClass.bug, graphQLId: 'eyes-neo'),
  AxiePart(name: 'Nerdy', slot: BodySlot.eyes, axieClass: AxieClass.bug, graphQLId: 'eyes-nerdy'),
  AxiePart(name: 'Kotaro', slot: BodySlot.eyes, axieClass: AxieClass.bug, graphQLId: 'eyes-kotaro'),
  AxiePart(name: 'Geisha', slot: BodySlot.eyes, axieClass: AxieClass.bug, graphQLId: 'eyes-geisha'),
  AxiePart(name: 'Dente', slot: BodySlot.eyes, axieClass: AxieClass.bug, graphQLId: 'eyes-dente'),

  // Reptile Eyes (6)
  AxiePart(name: 'Tricky', slot: BodySlot.eyes, axieClass: AxieClass.reptile, graphQLId: 'eyes-tricky'),
  AxiePart(name: 'Topaz', slot: BodySlot.eyes, axieClass: AxieClass.reptile, graphQLId: 'eyes-topaz'),
  AxiePart(name: 'Scar', slot: BodySlot.eyes, axieClass: AxieClass.reptile, graphQLId: 'eyes-scar'),
  AxiePart(name: 'Kabuki', slot: BodySlot.eyes, axieClass: AxieClass.reptile, graphQLId: 'eyes-kabuki'),
  AxiePart(name: 'Crimson Tooth', slot: BodySlot.eyes, axieClass: AxieClass.reptile, graphQLId: 'eyes-crimson-tooth'),
  AxiePart(name: 'Scarlet Frog', slot: BodySlot.eyes, axieClass: AxieClass.reptile, graphQLId: 'eyes-scarlet-frog'),

  // ==========================================
  // EARS (36 parts: 6 per class * 6 classes)
  // ==========================================
  // Beast Ears (6)
  AxiePart(name: 'Nut Cracker', slot: BodySlot.ears, axieClass: AxieClass.beast, graphQLId: 'ears-nut-cracker'),
  AxiePart(name: 'Nyan', slot: BodySlot.ears, axieClass: AxieClass.beast, graphQLId: 'ears-nyan'),
  AxiePart(name: 'Pointy Nyan', slot: BodySlot.ears, axieClass: AxieClass.beast, graphQLId: 'ears-pointy-nyan'),
  AxiePart(name: 'Innocent Lamb', slot: BodySlot.ears, axieClass: AxieClass.beast, graphQLId: 'ears-innocent-lamb'),
  AxiePart(name: 'Belieber', slot: BodySlot.ears, axieClass: AxieClass.beast, graphQLId: 'ears-belieber'),
  AxiePart(name: 'Puppy', slot: BodySlot.ears, axieClass: AxieClass.beast, graphQLId: 'ears-puppy'),

  // Aquatic Ears (6)
  AxiePart(name: 'Nimo', slot: BodySlot.ears, axieClass: AxieClass.aquatic, graphQLId: 'ears-nimo'),
  AxiePart(name: 'Tiny Fan', slot: BodySlot.ears, axieClass: AxieClass.aquatic, graphQLId: 'ears-tiny-fan'),
  AxiePart(name: 'Bubblemaker', slot: BodySlot.ears, axieClass: AxieClass.aquatic, graphQLId: 'ears-bubblemaker'),
  AxiePart(name: 'Gill', slot: BodySlot.ears, axieClass: AxieClass.aquatic, graphQLId: 'ears-gill'),
  AxiePart(name: 'Seabream', slot: BodySlot.ears, axieClass: AxieClass.aquatic, graphQLId: 'ears-seabream'),
  AxiePart(name: 'Inkling', slot: BodySlot.ears, axieClass: AxieClass.aquatic, graphQLId: 'ears-inkling'),

  // Plant Ears (6)
  AxiePart(name: 'Serious', slot: BodySlot.ears, axieClass: AxieClass.plant, graphQLId: 'ears-serious'),
  AxiePart(name: 'Sakura', slot: BodySlot.ears, axieClass: AxieClass.plant, graphQLId: 'ears-sakura'),
  AxiePart(name: 'Leaves', slot: BodySlot.ears, axieClass: AxieClass.plant, graphQLId: 'ears-leaves'),
  AxiePart(name: 'Clover', slot: BodySlot.ears, axieClass: AxieClass.plant, graphQLId: 'ears-clover'),
  AxiePart(name: 'Rosa', slot: BodySlot.ears, axieClass: AxieClass.plant, graphQLId: 'ears-rosa'),
  AxiePart(name: 'Hollow', slot: BodySlot.ears, axieClass: AxieClass.plant, graphQLId: 'ears-hollow'),

  // Bird Ears (6)
  AxiePart(name: 'Pink Cheek', slot: BodySlot.ears, axieClass: AxieClass.bird, graphQLId: 'ears-pink-cheek'),
  AxiePart(name: 'Early Bird', slot: BodySlot.ears, axieClass: AxieClass.bird, graphQLId: 'ears-early-bird'),
  AxiePart(name: 'Owl', slot: BodySlot.ears, axieClass: AxieClass.bird, graphQLId: 'ears-owl'),
  AxiePart(name: 'Curved Spine', slot: BodySlot.ears, axieClass: AxieClass.bird, graphQLId: 'ears-curved-spine'),
  AxiePart(name: 'Peace Maker', slot: BodySlot.ears, axieClass: AxieClass.bird, graphQLId: 'ears-peace-maker'),
  AxiePart(name: 'Risky Bird', slot: BodySlot.ears, axieClass: AxieClass.bird, graphQLId: 'ears-risky-bird'),

  // Bug Ears (6)
  AxiePart(name: 'Beetle Spike', slot: BodySlot.ears, axieClass: AxieClass.bug, graphQLId: 'ears-beetle-spike'),
  AxiePart(name: 'Ear Breathing', slot: BodySlot.ears, axieClass: AxieClass.bug, graphQLId: 'ears-ear-breathing'),
  AxiePart(name: 'Larva', slot: BodySlot.ears, axieClass: AxieClass.bug, graphQLId: 'ears-larva'),
  AxiePart(name: 'Tassels', slot: BodySlot.ears, axieClass: AxieClass.bug, graphQLId: 'ears-tassels'),
  AxiePart(name: 'Caterpillars', slot: BodySlot.ears, axieClass: AxieClass.bug, graphQLId: 'ears-caterpillars'),
  AxiePart(name: 'Vector', slot: BodySlot.ears, axieClass: AxieClass.bug, graphQLId: 'ears-vector'),

  // Reptile Ears (6)
  AxiePart(name: 'Pogona', slot: BodySlot.ears, axieClass: AxieClass.reptile, graphQLId: 'ears-pogona'),
  AxiePart(name: 'Frizzy', slot: BodySlot.ears, axieClass: AxieClass.reptile, graphQLId: 'ears-frizzy'),
  AxiePart(name: 'Small Frill', slot: BodySlot.ears, axieClass: AxieClass.reptile, graphQLId: 'ears-small-frill'),
  AxiePart(name: 'Curved Spine', slot: BodySlot.ears, axieClass: AxieClass.reptile, graphQLId: 'ears-curved-spine'),
  AxiePart(name: 'Sidebar', slot: BodySlot.ears, axieClass: AxieClass.reptile, graphQLId: 'ears-sidebar'),
  AxiePart(name: 'Swirl', slot: BodySlot.ears, axieClass: AxieClass.reptile, graphQLId: 'ears-swirl'),
];

/// Helper to generate the exact 288 mouth-tail permutation pairs.
List<MapEntry<String, String>> generatePermutations() {
  final List<MapEntry<String, String>> permutations = [];

  final Map<AxieClass, List<String>> mouthsByClass = {};
  final Map<AxieClass, List<String>> tailsByClass = {};

  for (final part in kAxiePartsCatalog) {
    if (part.slot == BodySlot.mouth) {
      mouthsByClass.putIfAbsent(part.axieClass, () => []).add(part.graphQLId);
    } else if (part.slot == BodySlot.tail) {
      tailsByClass.putIfAbsent(part.axieClass, () => []).add(part.graphQLId);
    }
  }

  void addCross(AxieClass mouthClass, AxieClass tailClass) {
    final mouths = mouthsByClass[mouthClass] ?? [];
    final tails = tailsByClass[tailClass] ?? [];
    for (final m in mouths) {
      for (final t in tails) {
        permutations.add(MapEntry(m, t));
      }
    }
  }

  // 1. Pure Lineages (144): 6 classes * (4 mouths * 6 tails) = 144
  for (final cls in AxieClass.values) {
    addCross(cls, cls);
  }

  // 2. Mech (48): Bug Mouth x Beast Tail (24) + Beast Mouth x Bug Tail (24)
  addCross(AxieClass.bug, AxieClass.beast);
  addCross(AxieClass.beast, AxieClass.bug);

  // 3. Dusk (48): Reptile Mouth x Aquatic Tail (24) + Aquatic Mouth x Reptile Tail (24)
  addCross(AxieClass.reptile, AxieClass.aquatic);
  addCross(AxieClass.aquatic, AxieClass.reptile);

  // 4. Dawn (48): Plant Mouth x Bird Tail (24) + Bird Mouth x Plant Tail (24)
  addCross(AxieClass.plant, AxieClass.bird);
  addCross(AxieClass.bird, AxieClass.plant);

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
  stdout.writeln('Pure Domain CLI Script — Cycle 11.9');
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

  // Phase 1: Query 204 Parts
  stdout.writeln('\n[Phase 1] Querying 204 anatomical body parts...');
  final List<String> partCsvLines = [
    'Part_Name,Slot,Class,GraphQL_ID,Axie_Amount',
  ];

  int partIndex = 0;
  for (final part in kAxiePartsCatalog) {
    partIndex++;
    stdout.write('[$partIndex/204] Fetching ${part.graphQLId}... ');
    final count = await client.fetchPartCount(part.graphQLId);
    stdout.writeln('$count');
    partCsvLines.add('${part.name},${part.slot.label},${part.axieClass.label},${part.graphQLId},$count');
    await Future<void>.delayed(const Duration(milliseconds: 75));
  }

  partStatsFile.writeAsStringSync('${partCsvLines.join('\n')}\n');
  stdout.writeln('✓ Successfully saved 204 parts to ${partStatsFile.path} (${partCsvLines.length} lines)');

  // Phase 2: Query 288 Mouth-Tail Permutations
  stdout.writeln('\n[Phase 2] Querying 288 mouth-tail genetic permutations...');
  final permutations = generatePermutations();
  assert(permutations.length == 288, 'Permutation count must equal exactly 288!');

  final List<String> permCsvLines = [
    'permutation_mouth_tail,Axie_amount',
  ];

  int permIndex = 0;
  for (final entry in permutations) {
    permIndex++;
    final mouthId = entry.key;
    final tailId = entry.value;
    final pairKey = '${mouthId}__$tailId';

    stdout.write('[$permIndex/288] Fetching $pairKey... ');
    final count = await client.fetchPermutationCount(mouthId, tailId);
    stdout.writeln('$count');
    permCsvLines.add('$pairKey,$count');
    await Future<void>.delayed(const Duration(milliseconds: 75));
  }

  permutationStatsFile.writeAsStringSync('${permCsvLines.join('\n')}\n');
  stdout.writeln('✓ Successfully saved 288 permutations to ${permutationStatsFile.path} (${permCsvLines.length} lines)');

  client.close();
  stdout.writeln('\n====================================================');
  stdout.writeln('CENSUS EXTRACTION COMPLETE!');
  stdout.writeln('====================================================');
}
