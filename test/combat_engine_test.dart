// ===============================================================================
// [MODULE_NAME]: combat_engine_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Tests / Domain
// [INTENT]: Unit tests covering interleaved drafting, priority inversion, rotating initiative, early lethal clash short-circuit, tactical buildings & auras
// [DEPENDENCIES]: combat_engine.dart, combat_enums.dart, game_state.dart, game_action.dart, board_unit_entity.dart, board_building_entity.dart, building_card_entity.dart, combat_card.dart, player_state_entity.dart, board_lane_entity.dart, axie_card_entity.dart
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
import 'package:lunacian_card_wars/src/domain/entities/combat/building_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/combat_card.dart';
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

List<CombatCard> createTestDeck(String prefix) {
  return [
    ...List.generate(15, (i) => createTestCard('${prefix}_u$i', 1, 10, 10)),
    BuildingCardEntity.attackTotem(id: '${prefix}_b_atk1'),
    BuildingCardEntity.attackTotem(id: '${prefix}_b_atk2'),
    BuildingCardEntity.defenseBarricade(id: '${prefix}_b_def1'),
    BuildingCardEntity.defenseBarricade(id: '${prefix}_b_def2'),
    BuildingCardEntity.vitalityShrine(id: '${prefix}_b_rep'),
  ];
}

GameState draftAllEightTilesInterleaved(CombatEngine engine, GameState state) {
  var s = state;
  final p1Tiles = [
    BoardClassAffinity.beast,
    BoardClassAffinity.aquatic,
    BoardClassAffinity.plant,
    BoardClassAffinity.bug,
  ];
  final p2Tiles = [
    BoardClassAffinity.aquatic,
    BoardClassAffinity.beast,
    BoardClassAffinity.bug,
    BoardClassAffinity.plant,
  ];

  for (int i = 0; i < 4; i++) {
    s = engine.reduce(s, PlaceTileAction(PlayerId.p1, i, p1Tiles[i]));
    s = engine.reduce(s, PlaceTileAction(PlayerId.p2, i, p2Tiles[i]));
  }
  return s;
}

void main() {
  late CombatEngine engine;

  setUp(() {
    engine = CombatEngine();
  });

  group('20-Card Decks & Interleaved Tile Drafting (AC-01, AC-05)', () {
    test('Initializes with 20 cards in deck, 0 in hand, and firstTilePlacer set', () {
      final p1Deck = createTestDeck('p1');
      final p2Deck = createTestDeck('p2');

      final state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);

      expect(state.p1.deck.length, 20);
      expect(state.p1.hand.length, 0);
      expect(state.p2.deck.length, 20);
      expect(state.p2.hand.length, 0);
      expect(state.phase, TurnPhase.turnZeroTilePlacement);
      expect(state.activePlayer, PlayerId.p1);
      expect(state.firstTilePlacer, PlayerId.p1);
      expect(state.initiativePlayer, PlayerId.p1);
    });

    test('Interleaved tile placement sequence enforces turn alternation and rejects out-of-turn placements', () {
      final p1Deck = createTestDeck('p1');
      final p2Deck = createTestDeck('p2');

      var state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);

      // P2 attempts to place out of turn -> rejected
      final illegalAttempt = engine.reduce(state, PlaceTileAction(PlayerId.p2, 0, BoardClassAffinity.beast));
      expect(illegalAttempt, equals(state));

      // P1 places tile on Lane 0 -> succeeds, active player toggles to P2
      state = engine.reduce(state, PlaceTileAction(PlayerId.p1, 0, BoardClassAffinity.beast));
      expect(state.lanes[0].p1Slot.tileAffinity, BoardClassAffinity.beast);
      expect(state.activePlayer, PlayerId.p2);

      // P1 attempts to place again -> rejected
      final p1Illegal = engine.reduce(state, PlaceTileAction(PlayerId.p1, 1, BoardClassAffinity.aquatic));
      expect(p1Illegal, equals(state));

      // P2 places tile on Lane 0 -> succeeds, active player toggles to P1
      state = engine.reduce(state, PlaceTileAction(PlayerId.p2, 0, BoardClassAffinity.aquatic));
      expect(state.lanes[0].p2Slot.tileAffinity, BoardClassAffinity.aquatic);
      expect(state.activePlayer, PlayerId.p1);

      // Complete remaining 6 interleaved placements
      state = engine.reduce(state, PlaceTileAction(PlayerId.p1, 1, BoardClassAffinity.aquatic));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p2, 1, BoardClassAffinity.beast));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p1, 2, BoardClassAffinity.plant));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p2, 2, BoardClassAffinity.bug));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p1, 3, BoardClassAffinity.bug));
      state = engine.reduce(state, PlaceTileAction(PlayerId.p2, 3, BoardClassAffinity.plant));

      // 8 tiles complete -> transitions to turnZeroMulligan, draws 4 cards each (deck: 16)
      expect(state.phase, TurnPhase.turnZeroMulligan);
      expect(state.activePlayer, PlayerId.p1);
      expect(state.p1.hand.length, 4);
      expect(state.p1.deck.length, 16);
      expect(state.p2.hand.length, 4);
      expect(state.p2.deck.length, 16);
    });
  });

  group('Priority Inversion & Dynamic Rotating Initiative (AC-02, AC-03)', () {
    test('Priority inversion in Round 1: second tile placer (P2) is awarded opening initiative', () {
      final p1Deck = createTestDeck('p1');
      final p2Deck = createTestDeck('p2');

      var state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);
      state = draftAllEightTilesInterleaved(engine, state);

      // Pass mulligans
      state = engine.reduce(state, PassPhaseAction(PlayerId.p1));
      state = engine.reduce(state, PassPhaseAction(PlayerId.p2));

      // Round 1 begins with Priority Inversion -> P2 gets opening initiative!
      expect(state.roundNumber, 1);
      expect(state.phase, TurnPhase.p2Turn);
      expect(state.activePlayer, PlayerId.p2);
      expect(state.initiativePlayer, PlayerId.p2);
      expect(state.p1.currentMana, 1);
      expect(state.p2.currentMana, 1);
    });

    test('Round-to-round rotating initiative across multiple rounds', () {
      final p1Deck = createTestDeck('p1');
      final p2Deck = createTestDeck('p2');

      var state = engine.initializeGame(p1Deck: p1Deck, p2Deck: p2Deck);
      state = draftAllEightTilesInterleaved(engine, state);
      state = engine.reduce(state, PassPhaseAction(PlayerId.p1));
      state = engine.reduce(state, PassPhaseAction(PlayerId.p2));

      // Round 1: P2 had initiative (Priority Inversion)
      expect(state.roundNumber, 1);
      expect(state.initiativePlayer, PlayerId.p2);
      expect(state.phase, TurnPhase.p2Turn);

      // P2 passes turn -> P1's turn
      state = engine.advancePhase(state);
      expect(state.phase, TurnPhase.p1Turn);
      expect(state.activePlayer, PlayerId.p1);

      // P1 passes second turn -> advances to clashPhase
      state = engine.advancePhase(state);
      expect(state.phase, TurnPhase.clashPhase);

      // Advance from clashPhase -> roundEnd with rotated initiative (P1)
      state = engine.advancePhase(state);
      expect(state.phase, TurnPhase.roundEnd);
      expect(state.initiativePlayer, PlayerId.p1);

      // Advance from roundEnd -> Round 2 starts with P1
      state = engine.advancePhase(state);
      expect(state.roundNumber, 2);
      expect(state.phase, TurnPhase.p1Turn);
      expect(state.initiativePlayer, PlayerId.p1);
      expect(state.activePlayer, PlayerId.p1);

      // Round 2 turns: P1 passes -> P2 passes -> clashPhase -> roundEnd
      state = engine.advancePhase(state);
      expect(state.phase, TurnPhase.p2Turn);
      state = engine.advancePhase(state);
      expect(state.phase, TurnPhase.clashPhase);
      state = engine.advancePhase(state);
      expect(state.phase, TurnPhase.roundEnd);
      expect(state.initiativePlayer, PlayerId.p2);

      // Round 3 starts with P2
      state = engine.advancePhase(state);
      expect(state.roundNumber, 3);
      expect(state.phase, TurnPhase.p2Turn);
      expect(state.initiativePlayer, PlayerId.p2);
    });
  });

  group('Lethal Clash Short-Circuit (AC-04)', () {
    test('Lethal clash short-circuiting at Lane 0 aborts subsequent lanes', () {
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
          // Lane 0: P1 has 30 ATK unit facing empty P2 slot -> Deals 30 dmg to P2 Hero HP (25 - 30 = -5 lethal!)
          BoardLaneEntity(
            laneIndex: 0,
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('lethal_u', 1, 30, 10), instanceId: 'u_lethal'),
            ),
            p2Slot: const LaneSlot(tileAffinity: BoardClassAffinity.beast),
          ),
          // Lane 1: P2 has 20 ATK unit facing empty P1 slot (would deal 20 to P1 if evaluated)
          BoardLaneEntity(
            laneIndex: 1,
            p1Slot: const LaneSlot(tileAffinity: BoardClassAffinity.aquatic),
            p2Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.aquatic,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p2_unresolved', 1, 20, 10), instanceId: 'u_unres'),
            ),
          ),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      final result = engine.resolveClashPhase(state);

      // P2 took lethal damage in Lane 0
      expect(result.p2.heroHp, -5);
      // Lane 1 was short-circuited: P1 took NO damage from Lane 1
      expect(result.p1.heroHp, 25);
      expect(result.phase, TurnPhase.gameOver);
      expect(result.winner, PlayerId.p1);

      // Verifies short-circuit log
      expect(result.logs.any((l) => l.contains('Clash aborted at Lane 0 due to lethal damage')), isTrue);
    });

    test('Simultaneous double-lethal on same lane results in draw and aborts subsequent lanes', () {
      final state = GameState(
        roundNumber: 1,
        phase: TurnPhase.clashPhase,
        activePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: const PlayerStateEntity(id: PlayerId.p1, heroHp: 20, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 20, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: [
          // Both strike with 25 unblocked damage -> Both HP drop to -5 simultaneously
          BoardLaneEntity(
            laneIndex: 0,
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p1_u', 1, 25, 5), instanceId: 'u1'),
            ),
            p2Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p2_u', 1, 25, 5), instanceId: 'u2'),
            ),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      final result = engine.resolveClashPhase(state);

      expect(result.p1.heroHp, 0);
      expect(result.p2.heroHp, 0);
      expect(result.phase, TurnPhase.gameOver);
      expect(result.winner, isNull); // Draw state
      expect(result.logs.any((l) => l.contains('Simultaneous double-lethal detected! Game over: Draw')), isTrue);
    });
  });

  group('Tactical Buildings, Auras & Trample (AC-05)', () {
    test('Attack Totem applies +2 ATK dynamic aura to allied unit in same lane', () {
      final totem = BuildingCardEntity.attackTotem(id: 'bldg_atk');
      final beast = createTestCard('c_beast', 1, 10, 10, axieClass: AxieElementalClass.beast);

      var state = GameState(
        roundNumber: 1,
        phase: TurnPhase.p1Turn,
        activePlayer: PlayerId.p1,
        initiativePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 3,
            maxMana: 3,
            hand: [totem, beast],
            deck: const [],
            graveyard: const [],
            canReact: false,
          ),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: [
          const BoardLaneEntity(
            laneIndex: 0,
            p1Slot: LaneSlot(tileAffinity: BoardClassAffinity.beast),
            p2Slot: LaneSlot(tileAffinity: BoardClassAffinity.beast),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Play building (cost 2)
      state = engine.reduce(state, PlayBuildingAction(PlayerId.p1, 0, totem.id));
      expect(state.lanes[0].p1Slot.building, isNotNull);
      expect(state.p1.currentMana, 1);

      // Play unit (cost 1)
      state = engine.reduce(state, PlayUnitAction(PlayerId.p1, beast, 0));
      expect(state.lanes[0].p1Slot.occupant, isNotNull);
      expect(state.p1.currentMana, 0);

      // Dynamic effective ATK should be 10 + 2 = 12
      expect(engine.getEffectiveAtk(state, 0, PlayerId.p1), 12);
    });

    test('Defense Barricade applies +5 DEF dynamic aura, absorbing damage before unit DEF is damaged', () {
      final barricade = BuildingCardEntity.defenseBarricade(id: 'bldg_def');
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
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p1_u', 1, 12, 10), instanceId: 'u1'),
            ),
            // P2 has 10 DEF unit + Defense Barricade (+5 DEF aura, 16 HP, 2 Armor) -> Total defense buffer = 15
            p2Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p2_u', 1, 0, 10), instanceId: 'u2'),
              building: BoardBuildingEntity.fromCard(barricade, instanceId: 'bldg_1'),
            ),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Strike of 12 ATK vs (10 unit DEF + 5 DEF aura = 15 total DEF)
      // 12 <= 15: No overflow!
      // Aura absorbs 5 dmg, remainder 7 dmg hits unit DEF (10 - 7 = 3 DEF left).
      final result = engine.resolveClashPhase(state);

      expect(result.lanes[0].p2Slot.occupant, isNotNull);
      expect(result.lanes[0].p2Slot.occupant!.currentDef, 3);
      expect(result.lanes[0].p2Slot.building!.currentHp, 16); // Building undamaged
      expect(result.p2.heroHp, 25); // Hero undamaged
    });

    test('Building trample arithmetic: excess overflow damages building minus armor, residual damages Hero HP', () {
      final barricade = BuildingCardEntity.defenseBarricade(id: 'bldg_def'); // 16 HP, 2 Armor, +5 DEF aura
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
              // Deals 30 unblocked damage
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p1_u', 1, 30, 10), instanceId: 'u1'),
            ),
            p2Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              // 5 DEF unit + Barricade (5 DEF aura, 16 HP, 2 armor) -> total DEF = 10
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p2_u', 1, 0, 5), instanceId: 'u2'),
              building: BoardBuildingEntity.fromCard(barricade, instanceId: 'bldg_1'),
            ),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Arithmetic breakdown:
      // 1. P1 deals 30 damage. Total DEF = 5 + 5 = 10. 30 > 10 -> Unit destroyed, overflow = 20.
      // 2. Overflow 20 hits Barricade with 2 Armor -> Effective building damage = 20 - 2 = 18.
      // 3. Barricade has 16 HP. 18 > 16 -> Barricade destroyed, bldgOverflow = 18 - 16 = 2.
      // 4. Residual trample 2 hits P2 Hero -> 25 - 2 = 23 HP!
      final result = engine.resolveClashPhase(state);

      expect(result.lanes[0].p2Slot.occupant, isNull);
      expect(result.lanes[0].p2Slot.building, isNull);
      expect(result.p2.heroHp, 23);
      expect(result.p2.graveyard.length, 1);
    });

    test('Vitality Shrine repair: heals up to 8 DEF at round start, capped at maxDef without overheal', () {
      final shrine = BuildingCardEntity.vitalityShrine(id: 'bldg_rep');
      var state = GameState(
        roundNumber: 1,
        phase: TurnPhase.roundEnd,
        activePlayer: PlayerId.p1,
        initiativePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 0,
            maxMana: 1,
            hand: const [],
            deck: [createTestCard('d1', 1, 1, 1)],
            graveyard: const [],
            canReact: false,
          ),
          PlayerId.p2: PlayerStateEntity(
            id: PlayerId.p2,
            heroHp: 25,
            maxHp: 25,
            currentMana: 0,
            maxMana: 1,
            hand: const [],
            deck: [createTestCard('d2', 1, 1, 1)],
            graveyard: const [],
            canReact: false,
          ),
        },
        lanes: [
          // Unit has maxDef 10, currentDef 3. Shrine effectValue = 8.
          // Heal amount = min(10 - 3, 8) = 7. Capped at 10 (no overheal).
          BoardLaneEntity(
            laneIndex: 0,
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('damaged_u', 1, 5, 10), instanceId: 'u1').copyWith(currentDef: 3),
              building: BoardBuildingEntity.fromCard(shrine, instanceId: 'bldg_shrine'),
            ),
            p2Slot: const LaneSlot(),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Advance from roundEnd triggers _startRound and repair hook
      state = engine.advancePhase(state);

      expect(state.roundNumber, 2);
      expect(state.lanes[0].p1Slot.occupant!.currentDef, 10); // Fully repaired to maxDef 10 without exceeding!
    });
  });
}
