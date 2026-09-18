---
type: sub_directive
id: SUB_DIRECTIVE_CYCLE_11_COMBAT_ENGINE_FSM
cycle: 11
version: 1.0
status: dispatched
target_agents:
  - data_agent (Engine & Domain Architect)
  - ui_agent (Presentation & Controller Architect)
  - qa_agent (Validation & Gatekeeper Architect)
author: der_tab (Director / Meta-Orchestrator)
created_at: 2026-09-17T19:07:00-06:00
system: lunacian_card_wars
tags:
  - combat_engine
  - domain_fsm
  - clean_architecture
  - riverpod
---

# SUB-DIRECTIVE: Cycle 11 — Deterministic Combat Engine & Reactive Game State FSM

## 1. Problem Statement
The application has established its navigation hub, atmospheric canvas, and decoupled Axie vault, but lacks its core gameplay domain: the deterministic, turn-based lane combat engine. The existing `ArenaView` is currently a static placeholder. To support the Axie Vibeathon Round 1 tactical loop, we must engineer a pure, side-effect-free domain Finite State Machine (FSM) representing symmetric 4-lane combat (`PlayerId.p1` vs `PlayerId.p2`), deterministic clash resolution with crits and trample damage, reactive windows, and a reactive Riverpod controller linking the domain model to `ArenaView`.

---

## 2. Acceptance Criteria

| ID | Criterion | Binary Metric |
|:---|:---|:---|
| **AC-01** | **Symmetric Immutable Game Topology**: Implement pure immutable domain entities: `combat_enums.dart`, `board_unit_entity.dart`, `board_building_entity.dart`, `board_lane_entity.dart`, `player_state_entity.dart`, `game_action.dart`, and root snapshot `game_state.dart`. Zero in-place mutations; full `copyWith` support. | PASS / FAIL |
| **AC-02** | **FSM Phase Progression**: Sequential phase flow: `turnZero` $\rightarrow$ `roundStart` $\rightarrow$ `p1Turn` $\rightarrow$ `p2Turn` $\rightarrow$ `p1ReactiveWindow` (conditional) $\rightarrow$ `clashPhase` $\rightarrow$ `roundEnd` $\rightarrow$ `gameOver`. Deterministic auto-advancement and pass phase rules. | PASS / FAIL |
| **AC-03** | **Sealed Action Dispatcher & Validation**: Sealed class hierarchy of `GameAction` (`PlayUnitAction`, `PlayBuildingAction`, `ActivateFloopAction`, `PassPhaseAction`, `ReactPlayAction`). Pure validator `getLegalActions(state, player)` rejecting illegal actions (insufficient mana, occupied slot, inactive player, already flooped, missing pips). Conditional `p1ReactiveWindow` trigger if P1 unit destroyed by P2 during `p2Turn` and P1 can react. | PASS / FAIL |
| **AC-04** | **Simultaneous Clash Engine with Trample & Crits**: Simultaneous 4-lane combat resolution: crit check (`currentPips == maxPips` $\rightarrow$ $\lfloor \text{ATK} \times 1.25 \rfloor$ & pips reset to 0; else $\text{ATK}$ & `currentPips++`), simultaneous mutual damage cross, trample overflow to building then to opponent Hero HP, reaping $\le 0$ DEF units/buildings to graveyard, and `gameOver` trigger if Hero HP $\le 0$. | PASS / FAIL |
| **AC-05** | **Riverpod Controller & ArenaView HUD**: `CombatEngineController` extending `Notifier<GameState>` (`combatEngineProvider`). Exposes `dispatchAction` and `startBattle`. `ArenaView` observes `combatEngineProvider` and displays live interactive HUD: Round, Phase, Hero HP, Mana, 4 Lanes with P1/P2 cards, and action trigger controls. | PASS / FAIL |
| **AC-06** | **Quality Gate & 100% Test Coverage**: `dart analyze --fatal-infos` yields 0 issues. `flutter test` executes all existing Cycle 10 navigation tests (16) + all new comprehensive `combat_engine_test.dart` suites with 100% pass rate. | PASS / FAIL |

---

## 3. Constraint Architecture

### 3.1. Technical & Stack Invariants
- **Stack**: Flutter Web 3.47+, Dart 3.x, Clean Architecture, Riverpod.
- **Purity & Determinism**: Absolutely zero calls to `DateTime.now()` or unseeded `Random()` inside `CombatEngine`. All calculations must be 100% deterministic and reproducible.
- **English AST Headers**: Every new or modified Dart file MUST start with the standard 6-field AST header block (`[MODULE_NAME]`, `[SYSTEM]`, `[DOMAIN]`, `[INTENT]`, `[DEPENDENCIES]`, `[ARCHITECTURE]`).
- **Hygiene**: No `.withOpacity()` (use `.withValues(alpha: ...)`). Use Dart 3 `sealed class`, pattern matching, and `switch` expressions.
- **Preservation**: Do NOT modify existing Cycle 10 entities (`AxieCardEntity`) or navigation controllers unless strictly extending compatibility. Existing 16 tests must remain green.

---

## 4. Decomposition & Division of Labor

### Module 1: Data / Engine Agent (Domain Models & Pure Combat Engine)
**Target Files:**
1. `lib/src/domain/entities/combat/combat_enums.dart`:
   - `enum PlayerId { p1, p2 }`
   - `enum TurnPhase { turnZero, roundStart, p1Turn, p2Turn, p1ReactiveWindow, clashPhase, roundEnd, gameOver }`
   - `enum BoardClassAffinity { beast, aquatic, plant, bird, bug, reptile, neutral }`
2. `lib/src/domain/entities/combat/board_unit_entity.dart`:
   - `BoardUnitEntity`: `instanceId`, `axieId`, `name`, `axieClass`, `currentAtk`, `currentDef`, `maxDef`, `currentPips`, `maxPips`, `hasFlooped`, `selectedFloop`, `spriteUrl`, `proxySpriteUrl`. `copyWith`.
3. `lib/src/domain/entities/combat/board_building_entity.dart`:
   - `BoardBuildingEntity`: `instanceId`, `name`, `currentHp`, `maxHp`, `armorReduction`. `copyWith`.
4. `lib/src/domain/entities/combat/board_lane_entity.dart`:
   - `LaneSlot`: `occupant` (`BoardUnitEntity?`), `building` (`BoardBuildingEntity?`). `copyWith`.
   - `BoardLaneEntity`: `laneIndex` (0..3), `affinity` (`BoardClassAffinity`), `p1Slot` (`LaneSlot`), `p2Slot` (`LaneSlot`). `copyWith`.
5. `lib/src/domain/entities/combat/player_state_entity.dart`:
   - `PlayerStateEntity`: `id` (`PlayerId`), `heroHp` (default 100), `currentMana`, `maxMana`, `hand` (`List<AxieCardEntity>`), `deck` (`List<AxieCardEntity>`), `graveyard` (`List<BoardUnitEntity>`), `canReact` (bool). `copyWith`.
6. `lib/src/domain/entities/combat/game_action.dart`:
   - Sealed class `GameAction`:
     - `PlayUnitAction(PlayerId player, AxieCardEntity card, int laneIndex)`
     - `PlayBuildingAction(PlayerId player, BoardBuildingEntity building, int laneIndex)`
     - `ActivateFloopAction(PlayerId player, int laneIndex, Map<String, dynamic>? params)`
     - `PassPhaseAction(PlayerId player)`
     - `ReactPlayAction(PlayerId player, AxieCardEntity card, int laneIndex)`
7. `lib/src/domain/entities/combat/game_state.dart`:
   - `GameState`: `roundNumber`, `phase` (`TurnPhase`), `activePlayer` (`PlayerId`), `players` (`Map<PlayerId, PlayerStateEntity>`), `lanes` (`List<BoardLaneEntity>`), `actionHistory` (`List<GameAction>`), `winner` (`PlayerId?`), `p1UnitDestroyedInP2Turn` (bool flag). `copyWith`.
8. `lib/src/domain/services/combat_engine.dart`:
   - Pure service:
     - `GameState initializeGame({required List<AxieCardEntity> p1Deck, required List<AxieCardEntity> p2Deck, int? seed})`
     - `List<GameAction> getLegalActions(GameState state, PlayerId player)`
     - `GameState reduce(GameState currentState, GameAction action)`
     - `GameState resolveClashPhase(GameState state)`
     - `GameState advancePhase(GameState state)`
9. `test/combat_engine_test.dart`:
   - Comprehensive unit test harness for all combat rules and edge cases.
10. **Evidence Persistence**:
    - `logs/CYCLE_11_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md`

### Module 2: UI Agent (Presentation Layer & Riverpod State)
**Target Files:**
1. `lib/src/presentation/controllers/combat_engine_controller.dart`:
   - `CombatEngineController` extending `Notifier<GameState>`.
   - `combatEngineProvider = NotifierProvider<CombatEngineController, GameState>(CombatEngineController.new)`.
   - Methods: `startBattle({List<AxieCardEntity>? p1Deck, List<AxieCardEntity>? p2Deck})`, `dispatchAction(GameAction action)`, `passPhase()`.
2. `lib/src/presentation/views/arena_view.dart`:
   - Reactive combat arena interface watching `combatEngineProvider`.
   - Top navigation bar with "← Return to Main Menu".
   - Tactical HUD: Round number, Phase badge, Player 1 & Player 2 Hero HP bars, Mana crystal counters.
   - 4-Lane Board Layout: Lanes 0..3 displaying Affinity, P2 Slot (top), Clash separator, P1 Slot (bottom).
   - Interactive Action Console: "Pass Phase", "Play Card (Lane 0..3)", "Trigger Clash".
3. **Evidence Persistence**:
    - `logs/CYCLE_11_MODULE_2_UI_AGENT_EXECUTION_REPORT.md`

### Module 3: QA Agent (Gatekeeper Audit & 4-Vector Verification)
1. Run `dart analyze --fatal-infos` & `flutter test`.
2. Audit all 4 vectors:
   - Vector A: Software (100% passing tests, 0 warnings).
   - Vector B: Math/Stats (Crit formula $\lfloor \text{ATK} \times 1.25 \rfloor$, simultaneous clash damage resolution, trample calculations down to 1 HP).
   - Vector C: Resource Profiling (Immutable state copies, zero heap leaks, zero `Paint` re-allocations in render loops).
   - Vector D: Architectural Integrity (AST Headers, Clean Architecture separation, Riverpod integration).
3. **Evidence Persistence**:
   - `logs/CYCLE_11_FINAL_AUDIT_PROMOTION_VERDICT.md` with uppercase verdict: `QA_VERDICT: [PROMOTION GRANTED]` or `[PROMOTION DENIED]`.

---

## 5. Eval Harness Commands
```bash
# 1. Static Analysis
dart analyze --fatal-infos

# 2. Test Suite
flutter test
```
