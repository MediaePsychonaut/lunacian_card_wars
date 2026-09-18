// ===============================================================================
// [MODULE_NAME]: combat_engine_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Tests / Domain
// [INTENT]: Comprehensive tests for dual-tile 8-landscape placement, affinity guards, Turn Zero mulligan, and pure clash resolution
// [DEPENDENCIES]: combat_engine.dart, combat_enums.dart, game_state.dart, game_action.dart, board_unit_entity.dart, board_building_entity.dart, player_state_entity.dart, board_lane_entity.dart, axie_card_entity.dart
// [ARCHITECTURE]: Unit Tests
// ===============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/combat_enums.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/game_state.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/game_action.dart';
import 'package:lunacian_card_wars/src/domain/services/combat_engine.dart';
import 'package:lunacian_card_wars/src/domain/entities/axie_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/board_unit_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/board_building_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/player_state_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/board_lane_entity.dart';

AxieCardEntity createTestCard(
  String id,
  int cost,
  int atk,
  int def, {
  AxieElementalClass axieClass = AxieElementalClass.beast,
  int initialPips = 0,
  int maxPips = 3,
}) {
  return AxieCardEntity(
    id: id,
    name: 'Test Axie $id',
    axieClass: axieClass,
    level: 1,
    manaCost: cost,
    baseAtk: atk,
    baseDef: def,
    initialPips: initialPips,
    maxPips: maxPips,
    mouthPartName: 'Basic',
    tailPartName: 'Basic',
    selectedFloop: FloopSource.mouth,
    spriteUrl: '',
    proxySpriteUrl: '',
    rawGenes: const {},
  );
}

GameState placeAllEightTiles(CombatEngine engine, GameState state) {
  var s = state;
  final affinities = [
    BoardClassAffinity.beast,
    BoardClassAffinity.aquatic,
    BoardClassAffinity.plant,
    BoardClassAffinity.bug,
  ];
  for (int i = 0; i < 4; i++) {
    s = engine.reduce(s, PlaceTileAction(PlayerId.p1, i, affinities[i]));
  }
  for (int i = 0; i < 4; i++) {
    s = engine.reduce(s, PlaceTileAction(PlayerId.p2, i, affinities[i]));
  }
  return s;
}

void main() {
  late CombatEngine engine;

  setUp(() {
    engine = CombatEngine();
  });

  group('Turn Zero: 8-Landscape Tile Placement & 15-Card Deck Initialization (AC-01, AC-02)', () {
    test('Initializes with 25 HP hero, 15 cards in deck, 0 cards in hand, 4 landscapes, turnZeroTilePlacement phase', () {
      final p1Deck = List.generate(15, (i) => createTestCard('p1_$i', 1, 10, 10));
      final p2Deck = List.generate(15, (i) => createTestCard('p2_$i', 1, 10, 10));

      final state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);

      expect(state.roundNumber, 1);
      expect(state.phase, TurnPhase.turnZeroTilePlacement);
      expect(state.activePlayer, PlayerId.p1);
      expect(state.initiativePlayer, PlayerId.p1);

      // Verify P1
      expect(state.p1.heroHp, 25);
      expect(state.p1.maxHp, 25);
      expect(state.p1.currentMana, 0);
      expect(state.p1.maxMana, 0);
      expect(state.p1.hand.length, 0);
      expect(state.p1.deck.length, 15);
      expect(state.p1.landscapeDeck, [
        BoardClassAffinity.beast,
        BoardClassAffinity.aquatic,
        BoardClassAffinity.plant,
        BoardClassAffinity.bug,
      ]);
      expect(state.p1.hasCompletedMulligan, isFalse);

      // Verify P2
      expect(state.p2.heroHp, 25);
      expect(state.p2.maxHp, 25);
      expect(state.p2.currentMana, 0);
      expect(state.p2.maxMana, 0);
      expect(state.p2.hand.length, 0);
      expect(state.p2.deck.length, 15);
      expect(state.p2.landscapeDeck, [
        BoardClassAffinity.beast,
        BoardClassAffinity.aquatic,
        BoardClassAffinity.plant,
        BoardClassAffinity.bug,
      ]);
      expect(state.p2.hasCompletedMulligan, isFalse);

      // Verify 4 lanes start with empty slot affinities
      expect(state.lanes.length, 4);
      for (int i = 0; i < 4; i++) {
        expect(state.lanes[i].p1Slot.tileAffinity, isNull);
        expect(state.lanes[i].p2Slot.tileAffinity, isNull);
      }

      // Verify telemetry logs
      expect(state.logs.isNotEmpty, isTrue);
      expect(state.logs.first, contains('Turn Zero: Landscape tile placement active'));
    });

    test('8-Tile placement sequence transitions to hand draw (4 cards each) and turnZeroMulligan phase', () {
      final p1Deck = List.generate(15, (i) => createTestCard('p1_$i', 1, 10, 10));
      final p2Deck = List.generate(15, (i) => createTestCard('p2_$i', 1, 10, 10));

      var state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);

      // P1 places 4 tiles
      state = engine.reduce(state, PlaceTileAction(PlayerId.p1, 0, BoardClassAffinity.beast));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p1, 1, BoardClassAffinity.aquatic));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p1, 2, BoardClassAffinity.plant));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p1, 3, BoardClassAffinity.bug));

      expect(state.lanes[0].p1Slot.tileAffinity, BoardClassAffinity.beast);
      expect(state.lanes[1].p1Slot.tileAffinity, BoardClassAffinity.aquatic);
      expect(state.lanes[2].p1Slot.tileAffinity, BoardClassAffinity.plant);
      expect(state.lanes[3].p1Slot.tileAffinity, BoardClassAffinity.bug);

      // Active player transitions to P2
      expect(state.activePlayer, PlayerId.p2);
      expect(state.phase, TurnPhase.turnZeroTilePlacement);

      // P2 places 4 tiles
      state = engine.reduce(state, PlaceTileAction(PlayerId.p2, 0, BoardClassAffinity.aquatic));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p2, 1, BoardClassAffinity.beast));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p2, 2, BoardClassAffinity.bug));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p2, 3, BoardClassAffinity.plant));

      // Dual-tile topology verification: independent per-slot affinities
      expect(state.lanes[0].p1Slot.tileAffinity, BoardClassAffinity.beast);
      expect(state.lanes[0].p2Slot.tileAffinity, BoardClassAffinity.aquatic);
      expect(state.lanes[1].p1Slot.tileAffinity, BoardClassAffinity.aquatic);
      expect(state.lanes[1].p2Slot.tileAffinity, BoardClassAffinity.beast);

      // Transition to turnZeroMulligan: both players draw 4 cards from deck
      expect(state.phase, TurnPhase.turnZeroMulligan);
      expect(state.activePlayer, PlayerId.p1);
      expect(state.p1.hand.length, 4);
      expect(state.p1.deck.length, 11);
      expect(state.p2.hand.length, 4);
      expect(state.p2.deck.length, 11);
    });

    test('MulliganAction swaps selected cards, redraws equal count, and preserves 15-card invariant', () {
      final p1Deck = List.generate(15, (i) => createTestCard('p1_$i', 1, 10, 10));
      final p2Deck = List.generate(15, (i) => createTestCard('p2_$i', 1, 10, 10));

      var state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);
      state = placeAllEightTiles(engine, state);

      expect(state.phase, TurnPhase.turnZeroMulligan);

      // P1 hand initially: p1_0, p1_1, p1_2, p1_3
      final initialP1HandIds = state.p1.hand.map((c) => c.id).toList();
      expect(initialP1HandIds, ['p1_0', 'p1_1', 'p1_2', 'p1_3']);

      // P1 mulligans 2 cards: p1_0 and p1_2
      state = engine.reduce(state, MulliganAction(PlayerId.p1, ['p1_0', 'p1_2']));

      expect(state.p1.hasCompletedMulligan, isTrue);
      expect(state.p1.hand.length, 4);
      expect(state.p1.deck.length, 11);

      // Cards drawn from top of deck should be p1_4 and p1_5
      final newHandIds = state.p1.hand.map((c) => c.id).toList();
      expect(newHandIds, containsAll(['p1_1', 'p1_3', 'p1_4', 'p1_5']));
      expect(newHandIds.contains('p1_0'), isFalse);
      expect(newHandIds.contains('p1_2'), isFalse);

      // Replaced cards are appended to the deck
      final deckIds = state.p1.deck.map((c) => c.id).toList();
      expect(deckIds.last, 'p1_2');
      expect(deckIds[deckIds.length - 2], 'p1_0');

      // State activePlayer transitions to P2
      expect(state.activePlayer, PlayerId.p2);

      // P2 passes mulligan (keeps hand)
      state = engine.reduce(state, PassPhaseAction(PlayerId.p2));

      expect(state.p2.hasCompletedMulligan, isTrue);

      // Automatic advance to Round 1 setup
      expect(state.phase, TurnPhase.p1Turn);
      expect(state.activePlayer, PlayerId.p1);
      expect(state.roundNumber, 1);
      expect(state.p1.currentMana, 1);
      expect(state.p1.maxMana, 1);
      expect(state.p2.currentMana, 1);
      expect(state.p2.maxMana, 1);
    });
  });

  group('Legal Actions Validation & Tile Affinity Guards (AC-02, AC-03)', () {
    test('Legal actions in turnZeroTilePlacement: only PlaceTileAction for active player', () {
      final p1Deck = List.generate(15, (i) => createTestCard('p1_$i', 1, 10, 10));
      final p2Deck = List.generate(15, (i) => createTestCard('p2_$i', 1, 10, 10));

      final state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);

      // P1 actions in turnZeroTilePlacement: 4 lanes * 4 landscape choices = 16 PlaceTileActions
      final p1Actions = engine.getLegalActions(state, PlayerId.p1);
      expect(p1Actions.whereType<PlaceTileAction>().length, 16);
      expect(p1Actions.whereType<PassPhaseAction>().isEmpty, isTrue);
      expect(p1Actions.whereType<MulliganAction>().isEmpty, isTrue);
      expect(p1Actions.whereType<PlayUnitAction>().isEmpty, isTrue);

      // P2 is not active yet
      final p2Actions = engine.getLegalActions(state, PlayerId.p2);
      expect(p2Actions.isEmpty, isTrue);
    });

    test('Tile affinity guard rejects mismatched unit class and permits matching class', () {
      final beastCard = createTestCard('c_beast', 1, 10, 10, axieClass: AxieElementalClass.beast);
      final aquaCard = createTestCard('c_aqua', 1, 10, 10, axieClass: AxieElementalClass.aquatic);
      final plantCard = createTestCard('c_plant', 1, 10, 10, axieClass: AxieElementalClass.plant);

      final p1Deck = [beastCard, aquaCard, plantCard, ...List.generate(12, (i) => createTestCard('p1_$i', 1, 5, 5))];
      final p2Deck = List.generate(15, (i) => createTestCard('p2_$i', 1, 10, 10));

      var state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);
      // Place tiles: Lane 0 = beast, Lane 1 = aquatic, Lane 2 = plant, Lane 3 = bug
      state = placeAllEightTiles(engine, state);

      // Pass mulligans to enter Round 1
      state = engine.reduce(state, PassPhaseAction(PlayerId.p1));
      state = engine.reduce(state, PassPhaseAction(PlayerId.p2));

      expect(state.phase, TurnPhase.p1Turn);
      expect(state.p1.currentMana, 1);

      // canPlayUnit checks
      // Beast card on Lane 0 (beast) -> TRUE
      expect(engine.canPlayUnit(state, PlayerId.p1, beastCard, 0), isTrue);
      // Beast card on Lane 1 (aquatic) -> FALSE
      expect(engine.canPlayUnit(state, PlayerId.p1, beastCard, 1), isFalse);
      // Aquatic card on Lane 1 (aquatic) -> TRUE
      expect(engine.canPlayUnit(state, PlayerId.p1, aquaCard, 1), isTrue);
      // Aquatic card on Lane 2 (plant) -> FALSE
      expect(engine.canPlayUnit(state, PlayerId.p1, aquaCard, 2), isFalse);
      // Plant card on Lane 2 (plant) -> TRUE
      expect(engine.canPlayUnit(state, PlayerId.p1, plantCard, 2), isTrue);

      // Legal actions reflect affinity filtering
      final legalPlays = engine.getLegalActions(state, PlayerId.p1).whereType<PlayUnitAction>().toList();

      // Beast card should only be playable in lane 0
      final beastPlays = legalPlays.where((a) => a.card.id == 'c_beast').toList();
      expect(beastPlays.length, 1);
      expect(beastPlays.first.laneIndex, 0);

      // Aqua card should only be playable in lane 1
      final aquaPlays = legalPlays.where((a) => a.card.id == 'c_aqua').toList();
      expect(aquaPlays.length, 1);
      expect(aquaPlays.first.laneIndex, 1);

      // Attempting illegal play into lane 1 with beastCard returns unchanged state
      final illegalAttempt = engine.reduce(state, PlayUnitAction(PlayerId.p1, beastCard, 1));
      expect(illegalAttempt.lanes[1].p1Slot.occupant, isNull);
      expect(illegalAttempt.p1.currentMana, 1); // Mana not spent

      // Playing matching beastCard into lane 0 succeeds
      final legalAttempt = engine.reduce(state, PlayUnitAction(PlayerId.p1, beastCard, 0));
      expect(legalAttempt.lanes[0].p1Slot.occupant, isNotNull);
      expect(legalAttempt.lanes[0].p1Slot.occupant!.name, 'Test Axie c_beast');
      expect(legalAttempt.p1.currentMana, 0);
    });

    test('Round 1 turn: mana gating and floop mechanics with affinity tiles', () {
      final cheapBeast = createTestCard('c_cheap', 1, 10, 10, axieClass: AxieElementalClass.beast);
      final expensiveBeast = createTestCard('c_expensive', 2, 20, 20, axieClass: AxieElementalClass.beast);

      final p1Deck = [cheapBeast, expensiveBeast, ...List.generate(13, (i) => createTestCard('rest_$i', 1, 5, 5))];
      final p2Deck = List.generate(15, (i) => createTestCard('p2_$i', 1, 10, 10));

      var state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);
      state = placeAllEightTiles(engine, state);
      state = engine.reduce(state, PassPhaseAction(PlayerId.p1));
      state = engine.reduce(state, PassPhaseAction(PlayerId.p2));

      expect(state.phase, TurnPhase.p1Turn);
      expect(state.p1.currentMana, 1);

      // P1 hand has cheapBeast (cost 1) and expensiveBeast (cost 2)
      final actions = engine.getLegalActions(state, PlayerId.p1);
      final playUnitActions = actions.whereType<PlayUnitAction>().toList();

      // Only 1-cost cheapBeast in lane 0 (beast tile) is legal; expensiveBeast costs 2 > 1 mana
      final cheapPlays = playUnitActions.where((a) => a.card.id == 'c_cheap').toList();
      final expPlays = playUnitActions.where((a) => a.card.id == 'c_expensive').toList();
      expect(cheapPlays.length, 1);
      expect(cheapPlays.first.laneIndex, 0);
      expect(expPlays.isEmpty, isTrue);

      // Play cheapBeast in lane 0
      state = engine.reduce(state, PlayUnitAction(PlayerId.p1, cheapBeast, 0));
      expect(state.lanes[0].p1Slot.occupant, isNotNull);
      expect(state.p1.currentMana, 0);

      // With 0 mana, no PlayUnitAction is legal
      final actionsAfterPlay = engine.getLegalActions(state, PlayerId.p1);
      expect(actionsAfterPlay.whereType<PlayUnitAction>().isEmpty, isTrue);

      // Floop action is available for lane 0 occupant
      final floopActions = actionsAfterPlay.whereType<ActivateFloopAction>().toList();
      expect(floopActions.length, 1);
      expect(floopActions.first.laneIndex, 0);

      // Activate Floop
      state = engine.reduce(state, ActivateFloopAction(PlayerId.p1, 0));
      expect(state.lanes[0].p1Slot.occupant!.hasFlooped, isTrue);

      // Cannot floop again in same round
      final actionsAfterFloop = engine.getLegalActions(state, PlayerId.p1);
      expect(actionsAfterFloop.whereType<ActivateFloopAction>().isEmpty, isTrue);
    });
  });

  group('Clash Phase Decomposition & Dual-Tile Topology (AC-01, AC-02, AC-06)', () {
    test('Simultaneous cross with pure cascading trample: Unit DEF -> Building -> Hero HP across dual tiles', () {
      final state = GameState(
        roundNumber: 1,
        phase: TurnPhase.clashPhase,
        activePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: const PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 0,
            maxMana: 0,
            hand: [],
            deck: [],
            graveyard: [],
            canReact: false,
          ),
          PlayerId.p2: const PlayerStateEntity(
            id: PlayerId.p2,
            heroHp: 25,
            maxHp: 25,
            currentMana: 0,
            maxMana: 0,
            hand: [],
            deck: [],
            graveyard: [],
            canReact: false,
          ),
        },
        lanes: [
          BoardLaneEntity(
            laneIndex: 0,
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p1_u', 1, 20, 10), instanceId: 'u1'),
            ),
            p2Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.plant,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p2_u', 1, 0, 10), instanceId: 'u2'),
              building: const BoardBuildingEntity(
                instanceId: 'bldg_1',
                name: 'Wooden Bunker',
                currentHp: 5,
                maxHp: 5,
                armorReduction: 2,
              ),
            ),
          ),
          const BoardLaneEntity(
            laneIndex: 1,
            p1Slot: LaneSlot(tileAffinity: BoardClassAffinity.aquatic),
            p2Slot: LaneSlot(tileAffinity: BoardClassAffinity.bug),
          ),
          const BoardLaneEntity(
            laneIndex: 2,
            p1Slot: LaneSlot(tileAffinity: BoardClassAffinity.plant),
            p2Slot: LaneSlot(tileAffinity: BoardClassAffinity.beast),
          ),
          const BoardLaneEntity(
            laneIndex: 3,
            p1Slot: LaneSlot(tileAffinity: BoardClassAffinity.bug),
            p2Slot: LaneSlot(tileAffinity: BoardClassAffinity.aquatic),
          ),
        ],
        actionHistory: const [],
      );

      final result = engine.resolveClashPhase(state);

      // Arithmetic breakdown:
      // P1 deals 20 ATK to P2 side.
      // 1. P2 Unit has 10 DEF. 20 > 10 -> Unit DEF drops to 0, overflow = 10.
      // 2. Overflow 10 hits Building with 2 armorReduction -> Effective building damage = 10 - 2 = 8.
      // 3. Building has 5 HP. 8 > 5 -> Building destroyed (HP 0), bldgOverflow = 8 - 5 = 3.
      // 4. Residual trample 3 hits P2 Hero: 25 - 3 = 22 HP!
      expect(result.p2.heroHp, 22);
      expect(result.p1.heroHp, 25);

      // Graveyard reaping
      expect(result.lanes[0].p2Slot.occupant, isNull);
      expect(result.lanes[0].p2Slot.building, isNull);
      expect(result.p2.graveyard.length, 1);
      expect(result.p2.graveyard.first.instanceId, 'u2');

      // P1 unit survives with 10 DEF
      expect(result.lanes[0].p1Slot.occupant, isNotNull);
      expect(result.lanes[0].p1Slot.occupant!.currentDef, 10);

      // Dual tile affinities preserved after clash
      expect(result.lanes[0].p1Slot.tileAffinity, BoardClassAffinity.beast);
      expect(result.lanes[0].p2Slot.tileAffinity, BoardClassAffinity.plant);
    });

    test('Pip Crit check: full pips deal floor(ATK * 1.25) and reset pips; non-full pips increment', () {
      final state = GameState(
        roundNumber: 1,
        phase: TurnPhase.clashPhase,
        activePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: const PlayerStateEntity(id: PlayerId.p1, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: [
          BoardLaneEntity(
            laneIndex: 0,
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('crit_u', 1, 20, 10, initialPips: 3, maxPips: 3), instanceId: 'u_crit'),
            ),
            p2Slot: const LaneSlot(tileAffinity: BoardClassAffinity.beast),
          ),
          BoardLaneEntity(
            laneIndex: 1,
            p1Slot: const LaneSlot(tileAffinity: BoardClassAffinity.aquatic),
            p2Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.aquatic,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('std_u', 1, 10, 10, initialPips: 1, maxPips: 3), instanceId: 'u_std'),
            ),
          ),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(tileAffinity: BoardClassAffinity.plant), p2Slot: LaneSlot(tileAffinity: BoardClassAffinity.plant)),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(tileAffinity: BoardClassAffinity.bug), p2Slot: LaneSlot(tileAffinity: BoardClassAffinity.bug)),
        ],
        actionHistory: const [],
      );

      final result = engine.resolveClashPhase(state);

      // Crit P1 dealt 25 damage -> P2 Hero HP: 25 - 25 = 0!
      expect(result.p2.heroHp, 0);
      expect(result.lanes[0].p1Slot.occupant!.currentPips, 0); // Pips reset on crit

      // P2 dealt 10 damage -> P1 Hero HP: 25 - 10 = 15
      expect(result.p1.heroHp, 15);
      expect(result.lanes[1].p2Slot.occupant!.currentPips, 2); // Pips incremented

      // Terminal evaluation triggers gameOver
      expect(result.phase, TurnPhase.gameOver);
      expect(result.winner, PlayerId.p1);
    });
  });

  group('25 HP Hero Lifecycle, Lethal & Fatigue Penalties (AC-01, AC-02)', () {
    test('Empty deck at round start triggers -5 HP fatigue penalty and terminates when HP <= 0', () {
      var state = GameState(
        roundNumber: 1,
        phase: TurnPhase.roundEnd,
        activePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: const PlayerStateEntity(id: PlayerId.p1, heroHp: 4, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: List.generate(4, (i) => BoardLaneEntity(laneIndex: i, p1Slot: const LaneSlot(), p2Slot: const LaneSlot())),
        actionHistory: const [],
      );

      // Advancing from roundEnd starts Round 2
      state = engine.advancePhase(state);

      // P1 deck is empty -> 4 HP - 5 HP = -1 HP (perished!)
      expect(state.p1.heroHp, -1);
      // P2 deck is empty -> 25 HP - 5 HP = 20 HP
      expect(state.p2.heroHp, 20);

      // Terminal evaluation triggers gameOver with P2 winning
      expect(state.phase, TurnPhase.gameOver);
      expect(state.winner, PlayerId.p2);
    });

    test('Round advance scales mana curve up to 10 ceiling and resets floops', () {
      var state = GameState(
        roundNumber: 9,
        phase: TurnPhase.roundEnd,
        activePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 0,
            maxMana: 9,
            hand: [],
            deck: [createTestCard('deck1', 1, 1, 1)],
            graveyard: const [],
            canReact: false,
          ),
          PlayerId.p2: PlayerStateEntity(
            id: PlayerId.p2,
            heroHp: 25,
            maxHp: 25,
            currentMana: 0,
            maxMana: 9,
            hand: [],
            deck: [createTestCard('deck2', 1, 1, 1)],
            graveyard: const [],
            canReact: false,
          ),
        },
        lanes: [
          BoardLaneEntity(
            laneIndex: 0,
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('flooped_u', 1, 5, 5), instanceId: 'u_f').copyWith(hasFlooped: true),
            ),
            p2Slot: const LaneSlot(tileAffinity: BoardClassAffinity.beast),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Round 9 -> Round 10
      state = engine.advancePhase(state);
      expect(state.roundNumber, 10);
      expect(state.p1.maxMana, 10);
      expect(state.p1.currentMana, 10);
      expect(state.lanes[0].p1Slot.occupant!.hasFlooped, isFalse); // Floop reset!

      // Round 10 -> Round 11 (capped at 10)
      state = state.copyWith(phase: TurnPhase.roundEnd);
      state = engine.advancePhase(state);
      expect(state.roundNumber, 11);
      expect(state.p1.maxMana, 10); // Clamped at 10
    });
  });

  group('Reactive Micro-Window Enforcement (AC-03)', () {
    test('Triggers p1ReactiveWindow when P1 unit was destroyed in P2 turn, P1 has mana, playable card with matching affinity, and empty slot', () {
      var state = GameState(
        roundNumber: 1,
        phase: TurnPhase.p2Turn,
        activePlayer: PlayerId.p2,
        p1UnitDestroyedInP2Turn: true,
        players: {
          PlayerId.p1: PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 1,
            maxMana: 1,
            hand: [createTestCard('rx_card', 1, 5, 5, axieClass: AxieElementalClass.beast)],
            deck: const [],
            graveyard: const [],
            canReact: true,
          ),
          PlayerId.p2: const PlayerStateEntity(
            id: PlayerId.p2,
            heroHp: 25,
            maxHp: 25,
            currentMana: 0,
            maxMana: 1,
            hand: [],
            deck: [],
            graveyard: [],
            canReact: false,
          ),
        },
        lanes: List.generate(
          4,
          (i) => BoardLaneEntity(
            laneIndex: i,
            p1Slot: const LaneSlot(tileAffinity: BoardClassAffinity.beast),
            p2Slot: const LaneSlot(tileAffinity: BoardClassAffinity.beast),
          ),
        ),
        actionHistory: const [],
      );

      state = engine.advancePhase(state);

      expect(state.phase, TurnPhase.p1ReactiveWindow);
      expect(state.activePlayer, PlayerId.p1);

      // P1 can play ReactPlayAction
      final actions = engine.getLegalActions(state, PlayerId.p1);
      final reactActions = actions.whereType<ReactPlayAction>().toList();
      expect(reactActions.isNotEmpty, isTrue);

      // Play reaction unit into lane 0
      state = engine.reduce(state, reactActions.first);
      expect(state.lanes[0].p1Slot.occupant, isNotNull);
      expect(state.p1.currentMana, 0);

      // Pass phase from reaction window leads to clashPhase
      state = engine.reduce(state, PassPhaseAction(PlayerId.p1));
      expect(state.phase, TurnPhase.clashPhase);
    });

    test('Auto-skips reactive window directly to clashPhase if P1 has 0 mana', () {
      final state = GameState(
        roundNumber: 1,
        phase: TurnPhase.p2Turn,
        activePlayer: PlayerId.p2,
        p1UnitDestroyedInP2Turn: true,
        players: {
          PlayerId.p1: PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 0, // 0 mana!
            maxMana: 1,
            hand: [createTestCard('rx_card', 1, 5, 5)],
            deck: const [],
            graveyard: const [],
            canReact: true,
          ),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 1, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: List.generate(4, (i) => BoardLaneEntity(laneIndex: i, p1Slot: const LaneSlot(), p2Slot: const LaneSlot())),
        actionHistory: const [],
      );

      final nextState = engine.advancePhase(state);
      expect(nextState.phase, TurnPhase.clashPhase);
    });

    test('Auto-skips reactive window directly to clashPhase if no P1 unit was destroyed', () {
      final state = GameState(
        roundNumber: 1,
        phase: TurnPhase.p2Turn,
        activePlayer: PlayerId.p2,
        p1UnitDestroyedInP2Turn: false, // Not destroyed!
        players: {
          PlayerId.p1: PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 2,
            maxMana: 2,
            hand: [createTestCard('rx_card', 1, 5, 5)],
            deck: const [],
            graveyard: const [],
            canReact: true,
          ),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 1, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: List.generate(4, (i) => BoardLaneEntity(laneIndex: i, p1Slot: const LaneSlot(), p2Slot: const LaneSlot())),
        actionHistory: const [],
      );

      final nextState = engine.advancePhase(state);
      expect(nextState.phase, TurnPhase.clashPhase);
    });

    test('Auto-skips reactive window directly to clashPhase if all P1 slots are occupied', () {
      final state = GameState(
        roundNumber: 1,
        phase: TurnPhase.p2Turn,
        activePlayer: PlayerId.p2,
        p1UnitDestroyedInP2Turn: true,
        players: {
          PlayerId.p1: PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 2,
            maxMana: 2,
            hand: [createTestCard('rx_card', 1, 5, 5)],
            deck: const [],
            graveyard: const [],
            canReact: true,
          ),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 1, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: List.generate(
          4,
          (i) => BoardLaneEntity(
            laneIndex: i,
            p1Slot: LaneSlot(occupant: BoardUnitEntity.fromAxieCard(createTestCard('u_$i', 1, 5, 5), instanceId: 'u_$i')),
            p2Slot: const LaneSlot(),
          ),
        ),
        actionHistory: const [],
      );

      final nextState = engine.advancePhase(state);
      expect(nextState.phase, TurnPhase.clashPhase);
    });
  });
}
