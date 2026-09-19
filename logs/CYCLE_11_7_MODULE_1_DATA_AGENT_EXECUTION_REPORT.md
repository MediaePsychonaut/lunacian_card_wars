# Cycle 11.7 Module 1 Execution Report: Interleaved Drafting, Dynamic Precedence, Early Lethal Resolution & Tactical Buildings

- **Directive**: `SUB_DIRECTIVE_CYCLE_11_7_INTERLEAVED_TILES_LETHAL_BUILDINGS.md`
- **Module**: Module 1 — Domain Models & Pure Deterministic Combat Engine Refactor
- **Agent**: `data_agent` (Senior Data Architect & Pure Domain Engine Specialist)
- **Status**: COMPLETE
- **Timestamp**: 2026-09-18T01:55:00-06:00
- **System**: `lunacian_card_wars`

---

## 1. Executive Summary

Module 1 of Cycle 11.7 delivers an extensive refinement of the combat engine to align with competitive tabletop rules and Master Spec v3.1:
1. **Interleaved Turn Zero Tile Drafting**: Alternating placement sequence (`[P_init -> P_react x 4]`). Turns toggle strictly after each placement until all 8 slots are filled, after which 4 cards are drawn from 20-card decks and the game transitions to `turnZeroMulligan`.
2. **First-Mover Compensation & Round 1 Priority Inversion**: The player who drafts the first tile (`firstTilePlacer`) concedes opening Round 1 initiative to the second tile placer (`P_react`).
3. **Dynamic Round-by-Round Initiative Rotation**: Initiative alternates cleanly between P1 and P2 at every round boundary (`roundEnd -> roundStart`), ensuring fair priority across all rounds.
4. **Lane-by-Lane Lethal Short-Circuit in Clash Phase**: Sequential lane resolution (0 to 3) aborts immediately when any Hero HP drops to $\le 0$. Subsequent lanes are not calculated. Simultaneous double-lethal on the same lane resolves as an immediate draw.
5. **20-Card Decks with 5 Tactical Building Cards & Auras**: Decks expand to 20 cards (15 Axies + 5 Buildings) implementing `CombatCard`. Buildings project persistent auras (`attackAura`: +2 ATK, `defenseAura`: +5 DEF) and round-start repair hooks (`roundStartRepair`: up to 8 DEF, capped at base maxDef without overheal).

Static analysis via `dart analyze --fatal-infos lib/src/domain test/combat_engine_test.dart` passes with **0 issues**.
Unit tests via `flutter test test/combat_engine_test.dart` achieve a **100% pass rate (10/10 tests passed)**.

---

## 2. File Modification Audit

### 2.1. [`lib/src/domain/entities/combat/combat_card.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/combat_card.dart) [NEW]
- Created common interface for all playable cards in combat decks:
  ```dart
  abstract class CombatCard {
    String get id;
    String get name;
    int get manaCost;
  }
  ```
- 6-field AST header intact.

### 2.2. [`lib/src/domain/entities/combat/building_card_entity.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/building_card_entity.dart) [NEW]
- Added `BuildingEffectType` enum (`attackAura`, `defenseAura`, `roundStartRepair`).
- Created `BuildingCardEntity implements CombatCard` with `id`, `name`, `manaCost`, `maxHp`, `armorReduction`, `effectType`, `effectValue`.
- Factory constructors:
  - `BuildingCardEntity.attackTotem({String? id})` (Cost: 2, HP: 12, Armor: 1, +2 ATK aura)
  - `BuildingCardEntity.defenseBarricade({String? id})` (Cost: 2, HP: 16, Armor: 2, +5 DEF aura)
  - `BuildingCardEntity.vitalityShrine({String? id})` (Cost: 3, HP: 14, Armor: 1, 8 DEF repair)
- 6-field AST header intact.

### 2.3. [`lib/src/domain/entities/axie_card_entity.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/axie_card_entity.dart)
- Implemented `CombatCard` interface with `@override` annotations on `id`, `name`, and `manaCost`.
- 6-field AST header updated.

### 2.4. [`lib/src/domain/entities/combat/board_building_entity.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/board_building_entity.dart)
- Added `final BuildingEffectType? effectType;` and `final int effectValue;`.
- Added factory `BoardBuildingEntity.fromCard(BuildingCardEntity card, {required String instanceId})`.
- Updated `copyWith` and 6-field AST header.

### 2.5. [`lib/src/domain/entities/combat/player_state_entity.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/player_state_entity.dart)
- Typed `hand` and `deck` as `List<CombatCard>` (supporting 20-card mixed decks).
- Added helper getters:
  - `List<AxieCardEntity> get unitHand => hand.whereType<AxieCardEntity>().toList();`
  - `List<BuildingCardEntity> get buildingHand => hand.whereType<BuildingCardEntity>().toList();`
- Updated constructor, `copyWith`, and 6-field AST header.

### 2.6. [`lib/src/domain/entities/combat/game_state.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/game_state.dart)
- Added `final PlayerId? firstTilePlacer;`.
- Retained `final PlayerId initiativePlayer;`.
- Updated constructor, `copyWith`, and 6-field AST header.

### 2.7. [`lib/src/domain/entities/combat/game_action.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/game_action.dart)
- Updated `PlayBuildingAction` to:
  ```dart
  class PlayBuildingAction extends GameAction {
    final PlayerId player;
    final int laneIndex;
    final String cardInstanceId;
    const PlayBuildingAction(this.player, this.laneIndex, this.cardInstanceId);
  }
  ```
- Retained `PlayUnitAction`, `ActivateFloopAction`, `PassPhaseAction`, `ReactPlayAction`, `MulliganAction`, `PlaceTileAction`.
- 6-field AST header intact.

### 2.8. [`lib/src/domain/services/combat_engine.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/services/combat_engine.dart)
- **`initializeGame`**: Accepts `List<CombatCard>` (20 cards per deck), initializes `firstTilePlacer`, empty hands, 0 mana.
- **Interleaved Tile Drafting (`_placeTile`)**: Toggles `activePlayer` after each valid tile placement. When 8th tile is placed, draws 4 cards each and transitions to `turnZeroMulligan`.
- **Round 1 Priority Inversion (`_prepareRoundOne`)**: Second tile placer `pReact = (firstTilePlacer == P1) ? P2 : P1` awarded Round 1 opening initiative (`initiativePlayer = pReact`, `activePlayer = pReact`, `phase = (pReact == P1) ? p1Turn : p2Turn`).
- **Dynamic Auras**: Implemented `getEffectiveAtk(state, lane, player)` and `getEffectiveDef(state, lane, player)` integrating `attackAura` and `defenseAura`.
- **Building Placement (`_playBuilding`)**: Validates mana, unoccupied building slot, deducts mana, removes card from hand, deploys `BoardBuildingEntity.fromCard`.
- **Round Start Repair Hook (`_startRound`)**: Heals unit DEF by `min(occupant.maxDef - occupant.currentDef, building.effectValue)` with zero overheal.
- **Sequential Lethal Short-Circuit (`resolveClashPhase`)**: Loops lanes 0..3; if any Hero HP $\le 0$, immediately aborts remaining lanes, logs short-circuit, and transitions to `gameOver`. Simultaneous double-lethal on same lane records a draw (`winner = null`).
- **Round-to-Round Rotating Initiative (`advancePhase`)**: Flips `initiativePlayer` at clash completion (`(initiative == P1) ? P2 : P1`), and honors dynamic sequence in `_startRound`.

### 2.9. [`test/combat_engine_test.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/test/combat_engine_test.dart)
- Comprehensive test suite covering all 8 criteria:
  1. 20-card deck invariant (15 units + 5 buildings).
  2. Interleaved tile drafting and out-of-turn rejection.
  3. Priority inversion in Round 1 (P2 opening).
  4. Round-to-round rotating initiative across multiple rounds.
  5. Early lethal short-circuiting at Lane 0 (subsequent lanes uncalculated).
  6. Simultaneous double-lethal on same lane resulting in draw.
  7. Attack Totem dynamic aura (+2 ATK).
  8. Defense Barricade dynamic aura (+5 DEF) absorbing damage.
  9. Building trample arithmetic with armor reduction.
  10. Vitality Shrine repair hook with maxDef ceiling.

---

## 3. Automated Verification Results

### 3.1. Static Analysis
```
dart analyze --fatal-infos lib/src/domain test/combat_engine_test.dart
Analyzing domain, combat_engine_test.dart...
No issues found!
```
**Exit Code**: 0 (0 errors, 0 warnings, 0 infos).

### 3.2. Unit Test Suite
```
flutter test test/combat_engine_test.dart
00:00 +10: All tests passed!
```
**Pass Rate**: 100% (10/10 tests passed).

---

## 4. Hand-off Specification for UI Agent (Module 2)

1. **Dual Cockpit**:
   - `CombatEngineController`: Use `playerState.unitHand` and `playerState.buildingHand` or `playerState.hand`.
   - Dispatch `PlayBuildingAction(player, laneIndex, cardId)` for building cards.
   - Dispatch `PlayUnitAction(player, card, laneIndex)` for Axie unit cards.
   - Display `[P2: TILE]` top, `⚔️ LANE X ⚔️` divider, and `[P1: TILE]` bottom.
   - Display Lane Building status (Name, HP, Armor, Aura effect) in the 4-lane board matrix.
2. **Turn Zero Interleaved Controls**:
   - Only allow placement buttons for the currently active player (`gameState.activePlayer`).
   - Active player alternates after each tile until 8 tiles are drafted.

---

## 5. Data Agent Verdict

```
===============================================================================
DATA_AGENT_VERDICT: [COMPLETE]
===============================================================================
Module 1 domain refactor for Cycle 11.7 is complete, verified with 100% test pass
rate and 0 analyzer issues, enforcing interleaved drafting, dynamic precedence,
early lethal clash short-circuit, and tactical building aura pipelines.
===============================================================================
```
