// ===============================================================================
// [MODULE_NAME]: combat_engine_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Tests / Domain
// [INTENT]: Comprehensive unit tests for Cycle 11.8: canonical Axies, floop pipeline, spells, overdraw, mulligan, and combat rules
// [DEPENDENCIES]: combat_engine.dart, combat_enums.dart, game_state.dart, game_action.dart, board_unit_entity.dart, building_card_entity.dart, spell_card_entity.dart, floop_ability_entity.dart, player_state_entity.dart, board_lane_entity.dart, axie_card_entity.dart, axie_card_factory.dart
// [ARCHITECTURE]: Unit Tests
// ===============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/combat_enums.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/game_state.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/game_action.dart';
import 'package:lunacian_card_wars/src/domain/services/combat_engine.dart';
import 'package:lunacian_card_wars/src/domain/services/axie_card_factory.dart';
import 'package:lunacian_card_wars/src/domain/entities/axie_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/board_unit_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/building_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/spell_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/floop_ability_entity.dart';
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
  FloopAbilityEntity? floop,
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
    floop: floop,
  );
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

  group('Canonical 20-Card Decks & Starters (AC-04, AC-07)', () {
    test('Initializes canonical 20-card deck with 12 Axies, 4 Buildings, and 4 Spells', () {
      final state = engine.initializeGame();

      expect(state.p1.deck.length, 20);
      expect(state.p2.deck.length, 20);
      expect(state.p1.hand.length, 0);
      expect(state.p2.hand.length, 0);

      // Verify composition
      final p1Deck = state.p1.deck;
      expect(p1Deck.whereType<AxieCardEntity>().length, 12);
      expect(p1Deck.whereType<BuildingCardEntity>().length, 4);
      expect(p1Deck.whereType<SpellCardEntity>().length, 4);

      // Verify canonical starter stats
      final buba = AxieCardFactory.bubaStarter();
      expect(buba.axieClass, AxieElementalClass.beast);
      expect(buba.manaCost, 3);
      expect(buba.baseAtk, 16);
      expect(buba.baseDef, 11);
      expect(buba.initialPips, 1);
      expect(buba.floop?.name, 'Brutal Claw');
      expect(buba.floop?.effectType, FloopEffectType.directDamage);
      expect(buba.floop?.effectValue, 5);

      final olek = AxieCardFactory.olekStarter();
      expect(olek.axieClass, AxieElementalClass.plant);
      expect(olek.manaCost, 3);
      expect(olek.baseAtk, 9);
      expect(olek.baseDef, 18);
      expect(olek.floop?.name, 'Forest Armor');
      expect(olek.floop?.effectType, FloopEffectType.restoreDef);
      expect(olek.floop?.effectValue, 6);

      final puffy = AxieCardFactory.puffyStarter();
      expect(puffy.axieClass, AxieElementalClass.aquatic);
      expect(puffy.manaCost, 3);
      expect(puffy.baseAtk, 14);
      expect(puffy.baseDef, 13);
      expect(puffy.floop?.name, 'Bubble Surge');
      expect(puffy.floop?.effectType, FloopEffectType.buffAtk);
      expect(puffy.floop?.effectValue, 4);
    });
  });

  group('Mulligan Deck Recovery & Seeded Reshuffle (AC-01, AC-02)', () {
    test('Mulligan returns selected cards to deck, reshuffles, and draws equal replacement cards', () {
      var state = engine.initializeGame();
      state = draftAllEightTilesInterleaved(engine, state);

      expect(state.phase, TurnPhase.turnZeroMulligan);
      expect(state.p1.hand.length, 4);
      expect(state.p1.deck.length, 16);

      final initialHandIds = state.p1.hand.map((c) => c.id).toList();
      final cardsToSwap = [initialHandIds[0], initialHandIds[1]];

      state = engine.reduce(state, MulliganAction(PlayerId.p1, cardsToSwap));

      expect(state.p1.hasCompletedMulligan, isTrue);
      expect(state.p1.hand.length, 4);
      expect(state.p1.deck.length, 16);

      // Verify unswapped cards remained in hand
      expect(state.p1.hand.any((c) => c.id == initialHandIds[2]), isTrue);
      expect(state.p1.hand.any((c) => c.id == initialHandIds[3]), isTrue);

      // Verify telemetry recorded seeded reshuffle
      expect(state.logs.any((l) => l.contains('Deck reshuffled with seeded RNG')), isTrue);
    });
  });

  group('7-Card Hand Cap & Bottom-of-Deck Overdraw (AC-03)', () {
    test('Drawing with 7 cards in hand triggers overdraw penalty, sending card to bottom of deck without shuffle', () {
      final deck = List.generate(10, (i) => createTestCard('d_$i', 1, 5, 5));
      final hand = List.generate(7, (i) => createTestCard('h_$i', 1, 5, 5));

      var state = GameState(
        roundNumber: 1,
        phase: TurnPhase.p1Turn,
        activePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 5,
            maxMana: 5,
            hand: hand,
            deck: deck,
            graveyard: const [],
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
        lanes: List.generate(4, (i) => BoardLaneEntity(laneIndex: i, p1Slot: const LaneSlot(), p2Slot: const LaneSlot())),
        actionHistory: const [],
      );

      final topCard = deck.first;
      expect(topCard.id, 'd_0');

      // Draw card
      state = engine.drawCard(state, PlayerId.p1);

      // Hand size remains strictly at capacity (7)
      expect(state.p1.hand.length, 7);

      // Deck size remains 10 (card was reinserted at the bottom)
      expect(state.p1.deck.length, 10);

      // Top card was d_0, now bottom card must be d_0
      expect(state.p1.deck.last.id, 'd_0');

      // New top card is d_1
      expect(state.p1.deck.first.id, 'd_1');

      // Telemetry log verification
      expect(state.logs.any((l) => l.contains('OVERDRAW PENALTY: Player p1 hand is full (7/7). Card [Test Axie d_0] sent to bottom of deck.')), isTrue);
    });
  });

  group('Floop Ability Pipeline & Once-Per-Round Guard (AC-05)', () {
    test('Floop executes effect, deducts mana, sets hasFloopedThisRound, and resets on round start', () {
      final buba = AxieCardFactory.bubaStarter(instanceId: 'p1_buba');
      final enemyTarget = createTestCard('p2_target', 1, 10, 10);

      var state = GameState(
        roundNumber: 1,
        phase: TurnPhase.p1Turn,
        activePlayer: PlayerId.p1,
        initiativePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: const PlayerStateEntity(
            id: PlayerId.p1,
            heroHp: 25,
            maxHp: 25,
            currentMana: 2,
            maxMana: 2,
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
              occupant: BoardUnitEntity.fromAxieCard(buba, instanceId: 'u_buba'),
            ),
            p2Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(enemyTarget, instanceId: 'u_enemy'),
            ),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Verify legal actions contain ActivateFloopAction
      final legalActions = engine.getLegalActions(state, PlayerId.p1);
      expect(legalActions.whereType<ActivateFloopAction>().length, 1);

      // Execute Floop: Brutal Claw (Cost 1, directDamage 5 to enemy unit)
      state = engine.reduce(state, ActivateFloopAction(PlayerId.p1, 0));

      // Mana deducted: 2 - 1 = 1
      expect(state.p1.currentMana, 1);

      // Enemy unit took 5 damage: DEF 10 - 5 = 5
      expect(state.lanes[0].p2Slot.occupant?.currentDef, 5);

      // Slot is marked as hasFloopedThisRound
      expect(state.lanes[0].p1Slot.hasFloopedThisRound, isTrue);

      // Cannot activate Floop again in same round
      final actionsAfterFloop = engine.getLegalActions(state, PlayerId.p1);
      expect(actionsAfterFloop.whereType<ActivateFloopAction>().isEmpty, isTrue);

      final secondAttempt = engine.reduce(state, ActivateFloopAction(PlayerId.p1, 0));
      expect(secondAttempt, equals(state));

      // Advance through round end to round start
      state = state.copyWith(phase: TurnPhase.roundEnd);
      state = engine.advancePhase(state);

      // Round 2 start: hasFloopedThisRound is reset to false!
      expect(state.roundNumber, 2);
      expect(state.lanes[0].p1Slot.hasFloopedThisRound, isFalse);
    });

    test('Self-buff and DEF-restore floops work accurately', () {
      final olek = AxieCardFactory.olekStarter(instanceId: 'p1_olek');
      final puffy = AxieCardFactory.puffyStarter(instanceId: 'p1_puffy');

      var state = GameState(
        roundNumber: 1,
        phase: TurnPhase.p1Turn,
        activePlayer: PlayerId.p1,
        initiativePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: const PlayerStateEntity(id: PlayerId.p1, heroHp: 25, maxHp: 25, currentMana: 5, maxMana: 5, hand: [], deck: [], graveyard: [], canReact: false),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: [
          BoardLaneEntity(
            laneIndex: 0,
            // Damaged Olek: 26 maxDef, 10 currentDef. Floop restores 6 DEF.
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.plant,
              occupant: BoardUnitEntity.fromAxieCard(olek, instanceId: 'u_olek').copyWith(currentDef: 10),
            ),
            p2Slot: const LaneSlot(),
          ),
          BoardLaneEntity(
            laneIndex: 1,
            // Puffy: 14 baseAtk. Floop buffs +4 ATK.
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.aquatic,
              occupant: BoardUnitEntity.fromAxieCard(puffy, instanceId: 'u_puffy'),
            ),
            p2Slot: const LaneSlot(),
          ),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Activate Olek Floop: Forest Armor (+6 DEF)
      state = engine.reduce(state, ActivateFloopAction(PlayerId.p1, 0));
      expect(state.lanes[0].p1Slot.occupant?.currentDef, 16);

      // Activate Puffy Floop: Bubble Surge (+4 ATK)
      state = engine.reduce(state, ActivateFloopAction(PlayerId.p1, 1));
      expect(state.lanes[1].p1Slot.occupant?.baseAtk, 18);
    });
  });

  group('Tactical Spells Pipeline (AC-06)', () {
    test('Potion of Vitality heals allied unit DEF and goes to graveyard', () {
      final potion = SpellCardEntity.potionOfVitality(id: 'spell_pot');
      final unit = createTestCard('c_unit', 1, 10, 20);

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
            hand: [potion],
            deck: const [],
            graveyard: const [],
            canReact: false,
          ),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: [
          BoardLaneEntity(
            laneIndex: 0,
            // Damaged unit with 10/20 DEF
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(unit, instanceId: 'u1').copyWith(currentDef: 10),
            ),
            p2Slot: const LaneSlot(),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Cast Potion of Vitality (1 mana, +6 DEF)
      state = engine.reduce(state, PlaySpellAction(
        player: PlayerId.p1,
        cardInstanceId: potion.id,
        targetLaneIndex: 0,
      ));

      // Mana deducted: 3 - 1 = 2
      expect(state.p1.currentMana, 2);

      // Unit healed by 6: 10 + 6 = 16 DEF
      expect(state.lanes[0].p1Slot.occupant?.currentDef, 16);

      // Spell removed from hand
      expect(state.p1.hand.isEmpty, isTrue);
    });

    test('Star Shuriken deals 5 direct unmitigated damage to enemy unit', () {
      final shuriken = SpellCardEntity.starShuriken(id: 'spell_shuriken');
      final enemyUnit = createTestCard('c_enemy', 1, 10, 5); // 5 DEF -> will be destroyed!

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
            hand: [shuriken],
            deck: const [],
            graveyard: const [],
            canReact: false,
          ),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: [
          BoardLaneEntity(
            laneIndex: 0,
            p1Slot: const LaneSlot(),
            p2Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(enemyUnit, instanceId: 'u_enemy'),
            ),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Cast Star Shuriken (2 mana, 5 dmg) -> enemy unit with 5 DEF destroyed!
      state = engine.reduce(state, PlaySpellAction(
        player: PlayerId.p1,
        cardInstanceId: shuriken.id,
        targetLaneIndex: 0,
      ));

      expect(state.p1.currentMana, 1);
      expect(state.lanes[0].p2Slot.occupant, isNull);
      expect(state.p2.graveyard.length, 1);
    });

    test('Lunar Blessing grants +3 persistent ATK to allied unit', () {
      final blessing = SpellCardEntity.lunarBlessing(id: 'spell_lunar');
      final unit = createTestCard('c_unit', 1, 10, 10);

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
            hand: [blessing],
            deck: const [],
            graveyard: const [],
            canReact: false,
          ),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 25, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: [
          BoardLaneEntity(
            laneIndex: 0,
            p1Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.beast,
              occupant: BoardUnitEntity.fromAxieCard(unit, instanceId: 'u1'),
            ),
            p2Slot: const LaneSlot(),
          ),
          const BoardLaneEntity(laneIndex: 1, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      // Cast Lunar Blessing (2 mana, +3 ATK)
      state = engine.reduce(state, PlaySpellAction(
        player: PlayerId.p1,
        cardInstanceId: blessing.id,
        targetLaneIndex: 0,
      ));

      expect(state.p1.currentMana, 1);
      expect(state.lanes[0].p1Slot.occupant?.baseAtk, 13);
    });
  });

  group('Interleaved Drafting, Precedence & Lethal Short-Circuit (AC-01, AC-02, AC-03, AC-04)', () {
    test('Priority inversion in Round 1: second tile placer (P2) gets opening initiative', () {
      var state = engine.initializeGame();
      state = draftAllEightTilesInterleaved(engine, state);
      state = engine.reduce(state, PassPhaseAction(PlayerId.p1));
      state = engine.reduce(state, PassPhaseAction(PlayerId.p2));

      expect(state.roundNumber, 1);
      expect(state.phase, TurnPhase.p2Turn);
      expect(state.activePlayer, PlayerId.p2);
      expect(state.initiativePlayer, PlayerId.p2);
    });

    test('Lethal clash short-circuiting at Lane 0 aborts subsequent lanes', () {
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
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('lethal_u', 1, 30, 10), instanceId: 'u_lethal'),
            ),
            p2Slot: const LaneSlot(tileAffinity: BoardClassAffinity.beast),
          ),
          BoardLaneEntity(
            laneIndex: 1,
            p1Slot: const LaneSlot(tileAffinity: BoardClassAffinity.aquatic),
            p2Slot: LaneSlot(
              tileAffinity: BoardClassAffinity.aquatic,
              occupant: BoardUnitEntity.fromAxieCard(createTestCard('p2_unres', 1, 20, 10), instanceId: 'u_unres'),
            ),
          ),
          const BoardLaneEntity(laneIndex: 2, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
          const BoardLaneEntity(laneIndex: 3, p1Slot: LaneSlot(), p2Slot: LaneSlot()),
        ],
        actionHistory: const [],
      );

      final result = engine.resolveClashPhase(state);

      expect(result.p2.heroHp, -5);
      expect(result.p1.heroHp, 25);
      expect(result.phase, TurnPhase.gameOver);
      expect(result.winner, PlayerId.p1);
      expect(result.logs.any((l) => l.contains('Clash aborted at Lane 0 due to lethal damage')), isTrue);
    });

    test('Simultaneous double-lethal on same lane results in draw', () {
      final state = GameState(
        roundNumber: 1,
        phase: TurnPhase.clashPhase,
        activePlayer: PlayerId.p1,
        players: {
          PlayerId.p1: const PlayerStateEntity(id: PlayerId.p1, heroHp: 20, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
          PlayerId.p2: const PlayerStateEntity(id: PlayerId.p2, heroHp: 20, maxHp: 25, currentMana: 0, maxMana: 0, hand: [], deck: [], graveyard: [], canReact: false),
        },
        lanes: [
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
      expect(result.winner, isNull);
      expect(result.logs.any((l) => l.contains('Simultaneous double-lethal detected! Game over: Draw')), isTrue);
    });
  });
}
