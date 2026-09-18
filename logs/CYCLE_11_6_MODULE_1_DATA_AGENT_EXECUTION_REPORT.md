# Cycle 11.6 Module 1 Execution Report: 8-Landscape Dual-Tile Board Topology, Elemental Affinity Guards & Turn Zero FSM Refactor

- **Directive**: `SUB_DIRECTIVE_CYCLE_11_6_DUAL_TILES_AFFINITY_AND_SYMMETRIC_TELEMETRY.md`
- **Module**: Module 1 — Domain Models & Pure Deterministic Combat Engine Refactor
- **Agent**: `data_agent` (Senior Data Architect & Pure Domain Engine Specialist)
- **Status**: COMPLETE
- **Timestamp**: 2026-09-17T23:08:00-06:00
- **System**: `lunacian_card_wars`

---

## 1. Executive Summary

Module 1 of Cycle 11.6 has successfully transitioned `lunacian_card_wars` from the legacy 4-lane shared affinity model to the canonical Master Spec v3.1 **8-landscape dual-tile topology**. The battlefield now accurately models 4 lanes wherein each player places 4 landscape tiles into lanes 0 to 3, creating an 8-tile asymmetric landscape grid (4 facing 4).

The domain engine enforces strict elemental affinity validation guards (`card.affinity == lane.getSlot(player).tileAffinity || card.affinity == BoardClassAffinity.neutral`), pre-game tile placement FSM sequence (`turnZeroTilePlacement`), post-placement initial hand draw (4 cards each from a 15-card deck), followed by the mulligan phase (`turnZeroMulligan`) and Round 1 initiation.

All domain files adhere to 100% English 6-field AST headers, strict immutability, zero side effects (no unseeded `Random`, no `DateTime.now()`), and static analysis via `dart analyze --fatal-infos lib/src/domain` reports **0 issues**.

---

## 2. File Modification Audit

### 2.1. [`lib/src/domain/entities/combat/combat_enums.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/combat_enums.dart)
- Updated `TurnPhase` enum to replace legacy `turnZero` with the two-stage pre-game sequence:
  ```dart
  enum TurnPhase {
    turnZeroTilePlacement,
    turnZeroMulligan,
    roundStart,
    p1Turn,
    p2Turn,
    p1ReactiveWindow,
    clashPhase,
    roundEnd,
    gameOver
  }
  ```
- Retained canonical `BoardClassAffinity` enum: `beast`, `aquatic`, `plant`, `bird`, `bug`, `reptile`, `neutral`.
- Preserved standard 6-field English AST Header.

### 2.2. [`lib/src/domain/entities/combat/board_lane_entity.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/board_lane_entity.dart)
- **`LaneSlot`**:
  - Added `final BoardClassAffinity? tileAffinity;`.
  - Updated `copyWith` with `BoardClassAffinity? tileAffinity` and `bool clearTileAffinity = false`.
- **`BoardLaneEntity`**:
  - Removed global `affinity` field (abolishing the shared-affinity fallacy).
  - Provided convenient player-scoped accessors:
    ```dart
    LaneSlot getSlot(PlayerId player) => player == PlayerId.p1 ? p1Slot : p2Slot;
    BoardLaneEntity copyWithSlot(PlayerId player, LaneSlot slot) =>
        player == PlayerId.p1 ? copyWith(p1Slot: slot) : copyWith(p2Slot: slot);
    ```
- Preserved standard 6-field English AST Header.

### 2.3. [`lib/src/domain/entities/combat/player_state_entity.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/player_state_entity.dart)
- Added `landscapeDeck` (`List<BoardClassAffinity>`, defaulting to `[beast, aquatic, plant, bug]`).
- Updated constructor and `copyWith` with complete field coverage and full immutability.
- Retained 25 HP hero defaults and `hasCompletedMulligan`.
- Preserved standard 6-field English AST Header.

### 2.4. [`lib/src/domain/entities/axie_card_entity.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/axie_card_entity.dart)
- Imported `combat/combat_enums.dart`.
- Added explicit affinity getter mapping `AxieElementalClass` to `BoardClassAffinity`:
  ```dart
  BoardClassAffinity get affinity => switch (axieClass) {
    AxieElementalClass.beast => BoardClassAffinity.beast,
    AxieElementalClass.aquatic => BoardClassAffinity.aquatic,
    AxieElementalClass.plant => BoardClassAffinity.plant,
    AxieElementalClass.bird => BoardClassAffinity.bird,
    AxieElementalClass.bug => BoardClassAffinity.bug,
    AxieElementalClass.reptile => BoardClassAffinity.reptile,
    _ => BoardClassAffinity.neutral,
  };
  ```
- Preserved standard 6-field English AST Header.

### 2.5. [`lib/src/domain/entities/combat/game_action.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/entities/combat/game_action.dart)
- Added `PlaceTileAction` to sealed hierarchy:
  ```dart
  class PlaceTileAction extends GameAction {
    final PlayerId player;
    final int laneIndex;
    final BoardClassAffinity affinity;
    const PlaceTileAction(this.player, this.laneIndex, this.affinity);
  }
  ```
- Preserved standard 6-field English AST Header.

### 2.6. [`lib/src/domain/services/combat_engine.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/lib/src/domain/services/combat_engine.dart)
- **`initializeGame`**:
  - Accepts optional `List<BoardClassAffinity>? p1Landscapes`, `List<BoardClassAffinity>? p2Landscapes`.
  - Initializes 4 lanes with empty slots (`LaneSlot()`), with `tileAffinity: null`.
  - Initial phase set to `TurnPhase.turnZeroTilePlacement`.
  - Initial hands start empty (`hand: []`); full 15 cards remain in `deck`.
  - Each player's `landscapeDeck` initialized to 4 landscape affinities.
  - Telemetry log: `'Game initialized. Turn Zero: Landscape tile placement active.'`.
- **Affinity Guard (`canPlayUnit`)**:
  - Gated by: valid lane index, sufficient mana (`currentMana >= card.manaCost`), vacant slot (`slot.occupant == null`), non-null tile affinity (`slot.tileAffinity != null`), and elemental match (`card.affinity == slot.tileAffinity || card.affinity == BoardClassAffinity.neutral`).
- **`getLegalActions`**:
  - `TurnPhase.turnZeroTilePlacement`: generates `PlaceTileAction` for active player across unplaced lane slots using unplaced landscape cards from `landscapeDeck`.
  - `TurnPhase.turnZeroMulligan`: generates `MulliganAction` (subsets of hand IDs) and `PassPhaseAction`.
  - Active turns (`p1Turn`, `p2Turn`, `p1ReactiveWindow`): filters playable unit actions through `canPlayUnit`.
- **`reduce`**:
  - Handled `PlaceTileAction`: assigns `tileAffinity` to the player's slot in the designated lane. When all 8 tiles (4 by P1, 4 by P2) are placed:
    - Automatically draws 4 cards from each player's deck into their hand (deck reduced to 11).
    - Transitions phase to `TurnPhase.turnZeroMulligan`.
  - Handled `PlayUnitAction` / `ReactPlayAction`: uses `lane.copyWithSlot(player, slot.copyWith(occupant: deterministicUnit))`.
  - Handled `PlayBuildingAction`: uses `lane.copyWithSlot(player, slot.copyWith(building: building))`.
  - Handled `ActivateFloopAction`: uses `lane.copyWithSlot(player, slot.copyWith(occupant: unit.copyWith(hasFlooped: true)))`.
  - Handled `PassPhaseAction`: delegates to `_passMulligan` during `turnZeroMulligan` or `advancePhase` during regular turns.
- **`advancePhase`**:
  - `turnZeroTilePlacement` $\rightarrow$ `_autoCompleteTilePlacement` (deterministically places remaining tiles if skipped).
  - `turnZeroMulligan` / `roundStart` $\rightarrow$ `_prepareRoundOne` (Round 1, 1 mana, `p1Turn`).
  - `resolveClashPhase` maintains `LaneSlot` instances across all 4 lanes preserving independent slot `tileAffinity`.
- Preserved standard 6-field English AST Header.

### 2.7. [`test/combat_engine_test.dart`](file:///C:/NeuroField/active_projects/lunacian_card_wars/test/combat_engine_test.dart)
- Comprehensively updated and expanded to test:
  1. `Turn Zero: 8-Landscape Tile Placement & 15-Card Deck Initialization (AC-01, AC-02)`:
     - 25 HP hero, 15 cards in deck, 0 in hand, 4 landscape tiles, `turnZeroTilePlacement` phase.
     - 8-tile placement sequence transitions to 4-card hand draw each and `turnZeroMulligan` phase.
     - `MulliganAction` swaps selected cards, preserves 15-card invariant, and transitions to Round 1.
  2. `Legal Actions Validation & Tile Affinity Guards (AC-02, AC-03)`:
     - `turnZeroTilePlacement` legal action generation (only `PlaceTileAction` for active player).
     - Tile affinity guard rejects mismatched unit class and permits matching class.
     - Mana gating and floop mechanics with affinity tiles.
  3. `Clash Phase Decomposition & Dual-Tile Topology (AC-01, AC-02, AC-06)`:
     - Dual-tile independent affinities preserved through clash.
     - Cascading trample arithmetic (Unit DEF $\rightarrow$ Building armor reduction $\rightarrow$ Hero HP).
     - Pip crit check (full pips deal $\lfloor \text{ATK} \times 1.25 \rfloor$ and reset; standard pips increment).
  4. `25 HP Hero Lifecycle, Lethal & Fatigue Penalties`:
     - Empty deck triggers -5 HP fatigue penalty.
     - Mana curve scales to 10 ceiling and resets floops.
  5. `Reactive Micro-Window Enforcement (AC-03)`:
     - P1 reactive window triggering and auto-skip criteria.
- Preserved standard 6-field English AST Header.

---

## 3. Domain Invariant Matrix

| Vector | Invariant Specification | Status |
|:---|:---|:---|
| **Topology** | 4 Lanes (0..3), each containing independent `p1Slot` and `p2Slot`. Each slot has nullable `tileAffinity` (`BoardClassAffinity?`). | **ENFORCED** |
| **P1/P2 Landscapes** | Each player defines exactly 4 landscape tiles in `landscapeDeck` alongside 15 Axie cards. | **ENFORCED** |
| **Turn Zero Phase 1** | `TurnPhase.turnZeroTilePlacement`: Hands empty (`0`), Decks full (`15`). Players place 4 tiles each via `PlaceTileAction`. | **ENFORCED** |
| **Turn Zero Phase 2** | `TurnPhase.turnZeroMulligan`: Activated once all 8 tiles placed. Hands drawn (`4`), Decks reduced (`11`). Single-pass selective redraw. | **ENFORCED** |
| **Summon Guard** | Unit play rejected unless `card.manaCost <= currentMana`, slot vacant, slot has tile, and `card.affinity == slot.tileAffinity || neutral`. | **ENFORCED** |
| **Clash Trample** | Unit DEF $\rightarrow$ Building HP (minus `armorReduction`) $\rightarrow$ Hero HP. Slot tile affinities preserved post-clash. | **ENFORCED** |
| **Determinism** | Zero unseeded `Random()`, zero `DateTime.now()`. Deterministic IDs generated from card ID, round, and action count. | **ENFORCED** |

---

## 4. Static Analysis Telemetry

```
dart analyze --fatal-infos lib/src/domain
Analyzing domain...
No issues found!
```
- **Exit Code**: 0
- **Total Issues**: 0

---

## 5. Hand-off Specification for UI Agent (Module 2)

The domain engine is fully ready for presentation integration in `ArenaView` and `CombatEngineController`:

1. **Dual Tile Badges in 4-Lane Matrix**:
   - Lane `i` has two distinct tile badges:
     - Top: `lane.p2Slot.tileAffinity?.name.toUpperCase() ?? 'NONE'`
     - Middle: `⚔️ LANE $i ⚔️`
     - Bottom: `lane.p1Slot.tileAffinity?.name.toUpperCase() ?? 'NONE'`
2. **Turn Zero Controls**:
   - During `TurnPhase.turnZeroTilePlacement`, display landscape tile placement buttons for active player using unplaced tiles from `playerState.landscapeDeck`.
   - Dispatch `PlaceTileAction(player, laneIndex, affinity)`.
   - Once all 8 tiles are placed, automatically show mulligan card selector checkboxes and "Confirm Mulligan" / "Keep Hand" buttons.
3. **Symmetrical Dual-Player Console**:
   - Player Scope selector (P1 / P2 toggle).
   - Card Picker dropdown/list displaying ID, Class, Cost, ATK, DEF, Pips.
   - Lane Picker (0..3).
   - Summon Button displaying affinity/mana validation feedback using `CombatEngine.canPlayUnit`.
   - Discrete Floop buttons (`Floop P1 L0..3`, `Floop P2 L0..3`).

---

## 6. Data Agent Verdict

```
===============================================================================
DATA_AGENT_VERDICT: [COMPLETE]
===============================================================================
Module 1 domain refactor for Cycle 11.6 is complete, fully tested, deterministic,
and 100% compliant with Master Spec v3.1 8-landscape dual-tile topology requirements.
===============================================================================
```
