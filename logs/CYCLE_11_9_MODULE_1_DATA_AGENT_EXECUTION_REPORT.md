# CYCLE 11.9 MODULE 1: DATA AGENT EXECUTION REPORT
**System**: `lunacian_card_wars`  
**Sub-Directive**: `SUB_DIRECTIVE_CYCLE_11_9_GRAPHQL_CENSUS_6_PARTS_AND_PERMUTATIONS.md`  
**Role**: `data_agent` (Senior Data Architect & Pure Domain Engine Specialist)  
**Timestamp**: 2026-09-19T11:55:00-06:00  

---

## 1. Executive Summary
This report formalizes the canonical taxonomy and demographic extraction architecture for the on-chain GraphQL census of Axie Infinity body parts and genetic permutations on the Ronin Network.

- **Primary Catalog**: Master taxonomy of **204 physical anatomical parts** across **6 anatomical slots** (Horns, Back, Mouth, Tail, Ears, Eyes) and **6 pure classes** (Beast, Aquatic, Plant, Bird, Bug, Reptile).
- **Secondary Matrix**: Exact matrix of **288 mouth-tail genetic permutations** covering all 144 pure lineages (24 per class x 6 classes) and 144 cross-class archetypes: 48 Mech (Bug x Beast + Beast x Bug), 48 Dusk (Reptile x Aquatic + Aquatic x Reptile), and 48 Dawn (Plant x Bird + Bird x Plant).
- **CLI Extraction Architecture**: Pure Dart standalone CLI script at [`tool/census/fetch_axie_census.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/tool/census/fetch_axie_census.dart) with zero Flutter dependencies, exponential backoff retries on HTTP 429/network drop, 75ms query pacing, and environment/`secrets.env` credential isolation.
- **Topological Integrity**: The extraction script and output datasets (`assets/data/*.csv`) are located strictly within `C:\NeuroField\active_projects\lunacian_card_wars\`. Zero code files in `C:\LatiCore\`.

---

## 2. Canonical 204 Anatomical Body Parts Taxonomy

### 2.1 Horns (36 parts — 6 per class)
- **Beast (6)**: Little Branch (`horn-little-branch`), Imp (`horn-imp`), Merry (`horn-merry`), Pocky (`horn-pocky`), Dual Blade (`horn-dual-blade`), Arco (`horn-arco`)
- **Aquatic (6)**: Babylonia (`horn-babylonia`), Teal Shell (`horn-teal-shell`), Clamshell (`horn-clamshell`), Anemone (`horn-anemone`), Oranda (`horn-oranda`), Shoal Star (`horn-shoal-star`)
- **Plant (6)**: Bamboo (`horn-bamboo`), Beech (`horn-beech`), Rose Bud (`horn-rose-bud`), Strawberry Shortcake (`horn-strawberry-shortcake`), Cactus (`horn-cactus`), Watermelon (`horn-watermelon`)
- **Bird (6)**: Eggshell (`horn-eggshell`), Cuckoo (`horn-cuckoo`), Trump (`horn-trump`), Kestrel (`horn-kestrel`), Wing Horn (`horn-wing-horn`), Feather Spear (`horn-feather-spear`)
- **Bug (6)**: Vall Ein (`horn-vall-ein`), Antenna (`horn-antenna`), Caterpillar (`horn-caterpillar`), Pliers (`horn-pliers`), Parasite (`horn-parasite`), Leaf Bug (`horn-leaf-bug`)
- **Reptile (6)**: Unko (`horn-unko`), Scaly Spear (`horn-scaly-spear`), Cerastes (`horn-cerastes`), Scaly Spoon (`horn-scaly-spoon`), Incisor (`horn-incisor`), Bumpy (`horn-bumpy`)

### 2.2 Back (36 parts — 6 per class)
- **Beast (6)**: Ronin (`back-ronin`), Hero (`back-hero`), Jaguar (`back-jaguar`), Risky Beast (`back-risky-beast`), Timber (`back-timber`), Furball (`back-furball`)
- **Aquatic (6)**: Hermit (`back-hermit`), Blue Moon (`back-blue-moon`), Goldfish (`back-goldfish`), Sponge (`back-sponge`), Anemone (`back-anemone`), Perch (`back-perch`)
- **Plant (6)**: Turnip (`back-turnip`), Shiitake (`back-shiitake`), Bidens (`back-bidens`), Watering Can (`back-watering-can`), Mint (`back-mint`), Pumpkin (`back-pumpkin`)
- **Bird (6)**: Pigeon Post (`back-pigeon-post`), Raven (`back-raven`), Cupid (`back-cupid`), Kingfisher (`back-kingfisher`), Tri Feather (`back-tri-feather`), Balloon (`back-balloon`)
- **Bug (6)**: Snail Shell (`back-snail-shell`), Garish Worm (`back-garish-worm`), Buzz Buzz (`back-buzz-buzz`), Sandal (`back-sandal`), Scarab (`back-scarab`), Spiky Wing (`back-spiky-wing`)
- **Reptile (6)**: Bone Sail (`back-bone-sail`), Tri Spikes (`back-tri-spikes`), Green Thorns (`back-green-thorns`), Indian Star (`back-indian-star`), Red Ear (`back-red-ear`), Croc (`back-croc`)

### 2.3 Mouth (24 parts — 4 per class)
- **Beast (4)**: Nutcracker (`mouth-nut-cracker`), Axie Kiss (`mouth-axie-kiss`), Goda (`mouth-goda`), Confident (`mouth-confident`)
- **Aquatic (4)**: Lam (`mouth-lam`), Risky Fish (`mouth-risky-fish`), Piranha (`mouth-piranha`), Catfish (`mouth-catfish`)
- **Plant (4)**: Serious (`mouth-serious`), Zigzag (`mouth-zigzag`), Herbivore (`mouth-herbivore`), Silence Whisper (`mouth-silence-whisper`)
- **Bird (4)**: Doubletalk (`mouth-doubletalk`), Peace Maker (`mouth-peace-maker`), Little Owl (`mouth-little-owl`), Hungry Bird (`mouth-hungry-bird`)
- **Bug (4)**: Mosquito (`mouth-mosquito`), Cute Bunny (`mouth-cute-bunny`), Square Teeth (`mouth-square-teeth`), Pincer (`mouth-pincer`)
- **Reptile (4)**: Toothless Bite (`mouth-toothless-bite`), Kotaro (`mouth-kotaro`), Razor Bite (`mouth-razor-bite`), Tiny Turtle (`mouth-tiny-turtle`)

### 2.4 Tail (36 parts — 6 per class)
- **Beast (6)**: Cottontail (`tail-cottontail`), Rice (`tail-rice`), Shiva (`tail-shiva`), Gerbil (`tail-gerbil`), Hare (`tail-hare`), Nutcracker (`tail-nut-cracker`)
- **Aquatic (6)**: Koi (`tail-koi`), Nimo (`tail-nimo`), Tadpole (`tail-tadpole`), Ranchu (`tail-ranchu`), Navaga (`tail-navaga`), Shrimp (`tail-shrimp`)
- **Plant (6)**: Carrot (`tail-carrot`), Cattail (`tail-cattail`), Hatsune (`tail-hatsune`), Yam (`tail-yam`), Potato Leaf (`tail-potato-leaf`), Hot Butt (`tail-hot-butt`)
- **Bird (6)**: Swallow (`tail-swallow`), Feather Fan (`tail-feather-fan`), The Last One (`tail-the-last-one`), Cloud (`tail-cloud`), Granma's Fan (`tail-granmas-fan`), Post Fight (`tail-post-fight`)
- **Bug (6)**: Ant (`tail-ant`), Twin Needle (`tail-twin-needle`), Fish Snack (`tail-fish-snack`), Gravel Ant (`tail-gravel-ant`), Pupae (`tail-pupae`), Thorny Caterpillar (`tail-thorny-caterpillar`)
- **Reptile (6)**: Wall Gecko (`tail-wall-gecko`), Iguana (`tail-iguana`), Tiny Dino (`tail-tiny-dino`), Snake Jar (`tail-snake-jar`), Gila (`tail-gila`), Grass Snake (`tail-grass-snake`)

### 2.5 Ears (36 parts — 6 per class)
- **Beast (6)**: Nut Cracker (`ears-nut-cracker`), Nyan (`ears-nyan`), Pointy Nyan (`ears-pointy-nyan`), Innocent Lamb (`ears-innocent-lamb`), Belieber (`ears-belieber`), Puppy (`ears-puppy`)
- **Aquatic (6)**: Nimo (`ears-nimo`), Tiny Fan (`ears-tiny-fan`), Bubblemaker (`ears-bubblemaker`), Gill (`ears-gill`), Seabream (`ears-seabream`), Inkling (`ears-inkling`)
- **Plant (6)**: Serious (`ears-serious`), Sakura (`ears-sakura`), Leaves (`ears-leaves`), Clover (`ears-clover`), Rosa (`ears-rosa`), Hollow (`ears-hollow`)
- **Bird (6)**: Pink Cheek (`ears-pink-cheek`), Early Bird (`ears-early-bird`), Owl (`ears-owl`), Curved Spine (`ears-curved-spine`), Peace Maker (`ears-peace-maker`), Risky Bird (`ears-risky-bird`)
- **Bug (6)**: Beetle Spike (`ears-beetle-spike`), Ear Breathing (`ears-ear-breathing`), Larva (`ears-larva`), Tassels (`ears-tassels`), Caterpillars (`ears-caterpillars`), Vector (`ears-vector`)
- **Reptile (6)**: Pogona (`ears-pogona`), Frizzy (`ears-frizzy`), Small Frill (`ears-small-frill`), Curved Spine (`ears-curved-spine`), Sidebar (`ears-sidebar`), Swirl (`ears-swirl`)

### 2.6 Eyes (36 parts — 6 per class)
- **Beast (6)**: Puppy (`eyes-puppy`), Calico Zee (`eyes-calico-zee`), Little Peas (`eyes-little-peas`), Chubby (`eyes-chubby`), Zeek (`eyes-zeek`), Snowflakes (`eyes-snowflakes`)
- **Aquatic (6)**: Sleepless (`eyes-sleepless`), Clear (`eyes-clear`), Gero (`eyes-gero`), Telescopes (`eyes-telescopes`), Insomnia (`eyes-insomnia`), Blosson (`eyes-blosson`)
- **Plant (6)**: Papi (`eyes-papi`), Blossom (`eyes-blossom`), Cucumber Slice (`eyes-cucumber-slice`), Confused (`eyes-confused`), Mistletoe (`eyes-mistletoe`), Dreamy Papi (`eyes-dreamy-papi`)
- **Bird (6)**: Mavis (`eyes-mavis`), Lucas (`eyes-lucas`), Robin (`eyes-robin`), Little Owl (`eyes-little-owl`), Sky Mavis (`eyes-sky-mavis`), Crimson Gecko (`eyes-crimson-gecko`)
- **Bug (6)**: Bookworm (`eyes-bookworm`), Neo (`eyes-neo`), Nerdy (`eyes-nerdy`), Kotaro (`eyes-kotaro`), Geisha (`eyes-geisha`), Dente (`eyes-dente`)
- **Reptile (6)**: Tricky (`eyes-tricky`), Topaz (`eyes-topaz`), Scar (`eyes-scar`), Kabuki (`eyes-kabuki`), Crimson Tooth (`eyes-crimson-tooth`), Scarlet Frog (`eyes-scarlet-frog`)

**Total**: 36 Horns + 36 Backs + 24 Mouths + 36 Tails + 36 Ears + 36 Eyes = **204 parts**.

---

## 3. Genetic Permutation Matrix (288 Pairs)
Cross-combination of 24 Mouths and 36 Tails:
- **144 Pure Lineages**: 6 classes x (4 mouths * 6 tails) = 144 pairs
- **48 Mech Combinations**:
  - Bug Mouth (4) x Beast Tail (6) = 24
  - Beast Mouth (4) x Bug Tail (6) = 24
- **48 Dusk Combinations**:
  - Reptile Mouth (4) x Aquatic Tail (6) = 24
  - Aquatic Mouth (4) x Reptile Tail (6) = 24
- **48 Dawn Combinations**:
  - Plant Mouth (4) x Bird Tail (6) = 24
  - Bird Mouth (4) x Plant Tail (6) = 24
- **Total Permutations**: 144 + 48 + 48 + 48 = **288 pairs**.

---

## 4. Script Implementation Specifications
File: [`tool/census/fetch_axie_census.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/tool/census/fetch_axie_census.dart)
- **Dependencies**: `dart:io`, `dart:convert`, `package:http/http.dart`. ZERO Flutter dependencies.
- **Endpoint**: `https://api-gateway.skymavis.com/graphql/axie-marketplace`
- **Headers**: `'Content-Type': 'application/json'`, `'X-API-Key': apiKey`
- **Pacing**: 75ms delay between consecutive requests.
- **Resilience**: Up to 5 retries with exponential backoff on HTTP 429 / 5xx / SocketException.
- **Datasets**:
  1. `assets/data/axie_part_stats_and_floops.csv`: 205 lines (1 header + 204 parts).
  2. `assets/data/mouth_tail_permutation_floops.csv`: 289 lines (1 header + 288 permutations).

---

## 5. Verdict
**DATA_AGENT_VERDICT: [COMPLETE]**
