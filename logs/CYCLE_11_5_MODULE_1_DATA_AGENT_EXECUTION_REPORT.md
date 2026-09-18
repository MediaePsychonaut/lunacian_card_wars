# Cycle 11.5 Module 1 Execution Report: Pure Domain Engine & FSM Refactor

- **Directive**: `SUB_DIRECTIVE_CYCLE_11_5_FSM_REFACTOR_AND_STATE_TELEMETRY.md`
- **Module**: Module 1 — Domain Entities & Pure Deterministic Combat Engine Refactor
- **Agent**: `data_agent` (Senior Data Architect & Pure Domain Engine Specialist)
- **Status**: COMPLETE
- **Timestamp**: 2026-09-17T22:18:00-06:00
- **System**: `lunacian_card_wars`

---

## 1. Executive Summary

Module 1 has achieved complete alignment of the domain model and pure combat engine with Master Spec v3.1 and Cycle 11.5 requirements. The combat engine now deterministically manages the full lifecycle: Turn Zero pre-game setup, 15-card deck invariants, 25 HP base hero pools, elemental lane affinities, selective single-pass mulligan, mana curve progression, 5-step decomposed clash resolution with cascading trample (Unit $\rightarrow$ Building $\rightarrow$ Hero HP), fatigue penalties, and strict reactive micro-window gating.

All unit tests pass at 100% (13/13 tests in `test/combat_engine_test.dart`), and static analysis via `dart analyze --fatal-infos` reports 0 errors and 0 warnings.

---

## 2. File Modification Audit

### 2.1. `lib/src/domain/entities/combat/player_state_entity.dart`
- Set `heroHp` default to exactly `25` (replacing legacy 100 HP).
- Added `maxHp` (int, default `25`).
- Added `hasCompletedMulligan` (bool, default `false`).
- Updated `copyWith` with full immutability and complete field coverage.
- Preserved standard 6-field English AST Header.

### 2.2. `lib/src/domain/entities/combat/game_action.dart`
- Added `MulliganAction` to sealed hierarchy:
  ```dart
  class MulliganAction extends GameAction {
    final PlayerId player;
    final List<String> cardInstanceIdsToReplace;
    const MulliganAction(this.player, this.cardInstanceIdsToReplace);
  }
  ```
- Preserved standard 6-field English AST Header.

### 2.3. `lib/src/domain/entities/combat/game_state.dart`
- Added `initiativePlayer` (`PlayerId`, default `PlayerId.p1`).
- Added `logs` (`List<String>`, default `const []`).
- Updated `copyWith` to handle `initiativePlayer`, `logs`, and all root fields.
- Preserved standard 6-field English AST Header.

### 2.4. `lib/src/domain/services/combat_engine.dart`
- **`initializeGame`**:
  - Sets up 4 lanes with elemental affinities: Lane 0 (`beast`), Lane 1 (`aquatic`), Lane 2 (`plant`), Lane 3 (`bug`).
  - Enforces 15-card starter decks: 4 drawn into hand, 11 remaining in deck.
  - Initializes heroes with `heroHp: 25`, `maxHp: 25`, `currentMana: 0`, `maxMana: 0`, `hasCompletedMulligan: false`.
  - Sets initial state: `roundNumber: 1`, `phase: TurnPhase.turnZero`, `activePlayer: PlayerId.p1`, `initiativePlayer: PlayerId.p1`, initial telemetry log.
- **`getLegalActions`**:
  - In `TurnPhase.turnZero`: allows `MulliganAction` (power-set combinations of hand IDs) and `PassPhaseAction` for active player who hasn't completed mulligan.
  - In active turns (`p1Turn`, `p2Turn`): allows `PlayUnitAction` (gated by mana and unoccupied slot), `ActivateFloopAction` (unflooped occupants), `PlayBuildingAction`, and `PassPhaseAction`.
  - In `p1ReactiveWindow`: allows `ReactPlayAction` (gated by mana and empty slot) and `PassPhaseAction`.
  - Inactive players or other phases return empty legal actions.
- **`reduce`**:
  - Handled `MulliganAction`: removes selected cards from hand, places them at the bottom of the deck, draws an equal number from the top of the deck, sets `hasCompletedMulligan: true`. If the other player has not mulliganed, switches `activePlayer` to that player; once both complete, advances automatically to Round 1.
  - Handled `PassPhaseAction` in `turnZero`: marks `hasCompletedMulligan: true` without card replacement, advancing active player or transitioning to Round 1.
  - Handled `PlayUnitAction` / `ReactPlayAction`: deducts mana, removes card from hand, generates deterministic instance ID, and assigns occupant to lane slot.
  - Handled `PlayBuildingAction`: places building into lane slot.
  - Handled `ActivateFloopAction`: marks `hasFlooped: true`.
- **`advancePhase`**:
  - `turnZero` / `roundStart` $\rightarrow$ Round 1 setup (`TurnPhase.p1Turn`, `currentMana: 1`, `maxMana: 1`).
  - `p1Turn` $\rightarrow$ `p2Turn` (`activePlayer: PlayerId.p2`).
  - `p2Turn` $\rightarrow$ Evaluates reactive window conditions:
    `p1UnitDestroyedInP2Turn` AND `currentMana >= 1` AND playable reaction card in hand AND empty P1 lane slot exists.
    If met $\rightarrow$ `TurnPhase.p1ReactiveWindow`, `activePlayer: PlayerId.p1`.
    Else $\rightarrow$ skips directly to `TurnPhase.clashPhase`.
  - `p1ReactiveWindow` $\rightarrow$ `TurnPhase.clashPhase`.
  - `clashPhase` $\rightarrow$ calls `resolveClashPhase`. If terminal $\rightarrow$ `TurnPhase.gameOver`. Else $\rightarrow$ `TurnPhase.roundEnd`.
  - `roundEnd` $\rightarrow$ `_startRound`: increments `roundNumber`, sets `maxMana = min(10, roundNumber)`, `currentMana = maxMana`, draws 1 card each if deck is non-empty (if empty, incurs -5 HP fatigue penalty), resets unit floops, and transitions to `TurnPhase.p1Turn`.
- **`resolveClashPhase`**:
  - Step 1 (Crit Check & Damage Calc): If `currentPips == maxPips`, deals $\lfloor \text{currentAtk} \times 1.25 \rfloor$ and resets pips to 0. Else deals `currentAtk` and increments pips.
  - Step 2 (Simultaneous Mutual Cross): Both lane strikes resolve simultaneously.
  - Step 3 (Cascading Trample): Damage breaks `Unit DEF` $\rightarrow$ overflow cascades to `Lane Building` (mitigated by `armorReduction`) $\rightarrow$ residual overflow damages opposing `Hero HP`.
  - Step 4 (Graveyard Reaping): Units and buildings with $\le 0$ DEF/HP are reaped, and units are moved to graveyard.
  - Step 5 (Terminal Evaluation): If any hero reaches $\le 0$ HP, assigns `winner` and transitions to `TurnPhase.gameOver`.
  - Discrete step telemetry appended to `state.logs`.

### 2.5. `test/combat_engine_test.dart`
- Expanded to 13 discrete test cases grouped by architectural vectors:
  1. `Turn Zero & 15-Card Deck Initialization (AC-01)`: 25 HP heroes, 15 cards (4 hand, 11 deck), 0 mana, Turn Zero phase, elemental lane affinities, selective mulligan redraw preserving 15 cards, Round 1 transition.
  2. `Legal Actions Validation & Turn Operations (AC-02, AC-03)`: Turn Zero gating, mana cost gating, unit placement, floop activation and single-use locking.
  3. `Clash Phase Decomposition & Cascading Trample Arithmetic (AC-02)`: Simultaneous cross with full trample cascade (Unit DEF $\rightarrow$ Building armor reduction $\rightarrow$ Hero HP), pip crit calculation and reset vs standard pip increment.
  4. `25 HP Hero Lifecycle, Lethal & Fatigue Penalties (AC-01, AC-02)`: Fatigue damage on empty deck at round start with lethal terminal evaluation, mana curve scaling up to 10 ceiling and floop resets.
  5. `Reactive Micro-Window Enforcement (AC-03)`: Positive trigger when all 4 conditions are met; auto-skipping when mana is 0, no unit was destroyed, or all slots are occupied.

---

## 3. Verification & Test Execution Telemetry

### 3.1. Unit Test Suite (`flutter test test/combat_engine_test.dart`)
```
00:00 +0: loading C:/NeuroField/active_projects/lunacian_card_wars/test/combat_engine_test.dart
00:00 +0: Turn Zero & 15-Card Deck Initialization (AC-01) Initializes with 25 HP hero, 15 cards (4 in hand, 11 in deck), 0 mana, Turn Zero phase
00:00 +1: Turn Zero & 15-Card Deck Initialization (AC-01) Initializes 4 lanes with canonical elemental affinities: beast, aquatic, plant, bug
00:00 +2: Turn Zero & 15-Card Deck Initialization (AC-01) MulliganAction swaps selected cards, redraws equal count, and preserves 15-card invariant
00:00 +3: Legal Actions Validation & Turn Operations (AC-02, AC-03) Legal actions in Turn Zero: only MulliganAction and PassPhaseAction
00:00 +4: Legal Actions Validation & Turn Operations (AC-02, AC-03) Round 1 turn: mana cost gating, unit placement, and floop mechanics
00:00 +5: Clash Phase Decomposition & Cascading Trample Arithmetic (AC-02) Simultaneous cross with pure cascading trample: Unit DEF -> Building -> Hero HP
00:00 +6: Clash Phase Decomposition & Cascading Trample Arithmetic (AC-02) Pip Crit check: full pips deal floor(ATK * 1.25) and reset pips; non-full pips increment
00:00 +7: 25 HP Hero Lifecycle, Lethal & Fatigue Penalties (AC-01, AC-02) Empty deck at round start triggers -5 HP fatigue penalty and terminates when HP <= 0
00:00 +8: 25 HP Hero Lifecycle, Lethal & Fatigue Penalties (AC-01, AC-02) Round advance scales mana curve up to 10 ceiling and resets floops
00:00 +9: Reactive Micro-Window Enforcement (AC-03) Triggers p1ReactiveWindow when P1 unit was destroyed in P2 turn, P1 has mana, playable card, and empty slot
00:00 +10: Reactive Micro-Window Enforcement (AC-03) Auto-skips reactive window directly to clashPhase if P1 has 0 mana
00:00 +11: Reactive Micro-Window Enforcement (AC-03) Auto-skips reactive window directly to clashPhase if no P1 unit was destroyed
00:00 +12: Reactive Micro-Window Enforcement (AC-03) Auto-skips reactive window directly to clashPhase if all P1 slots are occupied
00:00 +13: All tests passed!
```
- Total Tests: 13
- Passed: 13 (100%)
- Failed: 0

### 3.2. Static Code Analysis (`dart analyze --fatal-infos lib/src/domain test/combat_engine_test.dart`)
```
Analyzing domain, combat_engine_test.dart...
No issues found!
```
- Total Warnings: 0
- Total Errors: 0
- Total Infos: 0

---

## 4. Architectural Invariants Sign-off
- **Determinism**: Zero unseeded `Random()` or `DateTime.now()` calls in pure domain engine.
- **Immutability**: All entities use immutable fields and pure `copyWith` pattern.
- **AST Compliance**: Standard 6-field AST headers intact across all touched domain files.
- **Clean Architecture**: Domain entities and engine services maintain zero presentation or framework leakage.

---

DATA_AGENT_VERDICT: [COMPLETE]
