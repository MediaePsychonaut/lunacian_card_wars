---
type: sub_directive
id: SUB_DIRECTIVE_CYCLE_11_6_DUAL_TILES_AFFINITY_AND_SYMMETRIC_TELEMETRY
cycle: 11.6
version: 1.0
status: dispatched
target_agents:
  - data_agent (Engine & Domain Architect)
  - ui_agent (Presentation & Telemetry Architect)
  - qa_agent (Validation & Gatekeeper Architect)
author: der_tab (Director / Meta-Orchestrator)
created_at: 2026-09-17T22:58:00-06:00
system: lunacian_card_wars
tags:
  - dual_tile_topology
  - landscape_architecture
  - affinity_validation
  - symmetrical_console
  - clean_architecture
  - riverpod
---

# SUB-DIRECTIVE: Cycle 11.6 — Board Topology Realignment, 8-Landscape Architecture, Tile Affinity Guards & Dual-Player Console

## 1. Problem Statement
The Cycle 11.5 engine resolved core pacing with 25 HP heroes, trample cascade, and a telemetry cockpit, but exhibited four fundamental divergences from the canonical Master Spec v3.1:
1. **Shared Lane Fallacy**: The battlefield modeled 4 global lanes with shared elemental affinities. Canonically, each player brings 4 landscape tiles, forming an 8-tile battlefield (4 facing 4 across the 4 lanes).
2. **Missing Tile Placement Sequence**: Turn Zero lacked a tile placement phase where players place their 4 landscapes into lanes 0 to 3 before card drawing and mulligans.
3. **Missing Card Typing & Affinity Guards**: The summoning engine did not enforce elemental tile matching (`card.affinity == lane.getSlot(player).tileAffinity`), permitting illegal cross-class deployments.
4. **Asymmetric & Blind Dispatcher**: The telemetry console only supported P1 and deployed blindly to the first affordable card without manual card picking or dual-player controls.

---

## 2. Acceptance Criteria

| ID | Criterion | Binary Metric |
|:---|:---|:---|
| **AC-01** | **8-Landscape Dual-Tile Board Topology**: `BoardLaneEntity` (lanes 0..3) models independent `p1Slot` and `p2Slot`, each possessing its own `tileAffinity` (`BoardClassAffinity?`). Each player's deck definition includes exactly 4 landscape tiles alongside their 15 Axie cards. | PASS / FAIL |
| **AC-02** | **Turn Zero Tile Placement Sequence**: `TurnPhase.turnZero` models a deterministic sequence: `turnZeroTilePlacement` where players place their 4 tiles via `PlaceTileAction(player, laneIndex, affinity)`. Once all 8 tiles are placed, 4 cards are drawn for each player and the phase transitions to `turnZeroMulligan`. After mulligans confirm, transition to Round 1 (`TurnPhase.p1Turn`, 1 mana). | PASS / FAIL |
| **AC-03** | **Typed Cards & Affinity Validation Guards**: `AxieCardEntity` exposes explicit `affinity` (`BoardClassAffinity`). `CombatEngine.getLegalActions` and `canPlayUnit` reject deployment if `card.affinity != lane.getSlot(player).tileAffinity`, or if mana is insufficient, or if slot is occupied. | PASS / FAIL |
| **AC-04** | **Symmetrical Dual-Player Interactive Telemetry Console**: Redesign action dispatcher in `ArenaView`: Player Scope Selector (toggle P1 / P2), Discrete Card Picker (dropdown/list of hand cards with ID, class, cost, ATK/DEF, pips), Lane Picker (0..3), Summon Button with affinity/mana validation feedback, dual-player Floop controls (`Floop P1 L0..3`, `Floop P2 L0..3`), and Turn Zero tile placement controls. | PASS / FAIL |
| **AC-05** | **Board Matrix Visual Update**: The 4-lane table in `ArenaView` displays two distinct tile badges per lane: Top P2 Tile Badge (`[P2: REPTILE]`) + P2 Slot details; Middle Clash Divider `⚔️ LANE X ⚔️`; Bottom P1 Tile Badge (`[P1: PLANT]`) + P1 Slot details. | PASS / FAIL |
| **AC-06** | **Automated Verification & Zero Regression**: `dart analyze --fatal-infos` reports 0 issues. `flutter test` achieves 100% pass rate with expanded unit tests verifying 8-tile placement, affinity guard rejection/acceptance, and dual-tile clash resolution. | PASS / FAIL |

---

## 3. Constraint Architecture

### 3.1. Technical & Stack Invariants
- **Stack**: Flutter Web 3.47+, Dart 3.x, Clean Architecture, Riverpod.
- **Purity & Determinism**: Zero unseeded `Random()` or `DateTime.now()` in domain logic.
- **English AST Headers**: All modified files must begin with the standard 6-field AST header.
- **Flutter Web Hygiene**: Strictly zero `.withOpacity()`; use `.withValues(alpha: ...)`. Zero RenderFlex overflows across desktop (1920x1080) and compact (800x600) viewports.
- **Layer Decoupling**: Domain engine contains zero presentation code; presentation communicates exclusively through `CombatEngineController`.

---

## 4. Decomposition & Division of Labor

### Module 1: Data / Engine Agent (Domain Models & Pure Engine Refactor)
**Target Files:**
1. `lib/src/domain/entities/combat/combat_enums.dart`:
   - Ensure `TurnPhase` supports `turnZeroTilePlacement` and `turnZeroMulligan` (or alias `turnZero` as `turnZeroTilePlacement`).
2. `lib/src/domain/entities/combat/board_lane_entity.dart`:
   - `LaneSlot`: Add `tileAffinity` (`BoardClassAffinity?`). Update `copyWith`.
   - `BoardLaneEntity`: Remove global affinity field; retain `laneIndex`, `p1Slot`, `p2Slot`. Provide `LaneSlot getSlot(PlayerId player)`.
3. `lib/src/domain/entities/combat/player_state_entity.dart`:
   - Add `landscapeDeck` (`List<BoardClassAffinity>`, default 4 tiles).
   - Update `copyWith`.
4. `lib/src/domain/entities/axie_card_entity.dart`:
   - Ensure explicit `BoardClassAffinity get affinity` mapping from `axieClass`.
5. `lib/src/domain/entities/combat/game_action.dart`:
   - Add `PlaceTileAction(PlayerId player, int laneIndex, BoardClassAffinity affinity)`.
6. `lib/src/domain/services/combat_engine.dart`:
   - Update `initializeGame`: Accept `List<BoardClassAffinity>? p1Landscapes`, `List<BoardClassAffinity>? p2Landscapes`. Initial lanes start with empty slots (`tileAffinity: null`). Initial phase is `TurnPhase.turnZeroTilePlacement`. Hand is empty; deck has 15 cards; landscapeDeck has 4 tiles each.
   - `getLegalActions`:
     * During `turnZeroTilePlacement`: Allow `PlaceTileAction` for active/unplaced tiles on unplaced lane slots.
     * During `turnZeroMulligan`: Allow `MulliganAction` and `PassPhaseAction`.
     * During active turns: Enforce affinity matching: `card.affinity == lane.getSlot(player).tileAffinity`.
   - `reduce`:
     * Handle `PlaceTileAction`: Assign `tileAffinity` to `lane.getSlot(player)`. Once all 8 tiles are placed (4 by P1, 4 by P2), automatically draw 4 cards each from deck into hand and transition to `turnZeroMulligan`.
     * Handle `PlayUnitAction`: Validate mana, vacant slot, and matching tile affinity.
   - Refactor clash and advancePhase to reflect dual-tile slots.
7. `test/combat_engine_test.dart`:
   - Add tests for Turn Zero tile placement flow, affinity rejection of mismatched class, affinity acceptance of matching class, and dual-tile clash resolution.
8. **Persistence**:
   - `logs/CYCLE_11_6_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md`

### Module 2: UI Agent (Presentation Layer & Symmetrical Console Refactor)
**Target Files:**
1. `lib/src/presentation/controllers/combat_engine_controller.dart`:
   - Support selected player (`PlayerId selectedPlayer`), selected card ID (`String? selectedCardId`), selected lane (`int selectedLane`).
   - Update test deck generation to include 4 landscape tiles and varied elemental classes (`beast`, `aquatic`, `plant`, `bug`, `bird`, `reptile`).
   - Expose methods: `selectPlayer(PlayerId)`, `selectCard(String? id)`, `selectLane(int lane)`, `placeTile(PlayerId player, int laneIndex, BoardClassAffinity affinity)`, `deploySelectedCard()`, `triggerFloop(PlayerId, int)`.
2. `lib/src/presentation/views/arena_view.dart`:
   - Update 4-Lane Matrix: Render separate P2 Tile Affinity Badge, Clash separator, and P1 Tile Affinity Badge.
   - Redesign Action Dispatcher into Symmetrical Dual-Player Console:
     * Player selector (P1 / P2 toggle).
     * Discrete Card Picker dropdown/list showing `[ID] Name | Class | Cost | ATK/DEF | Pips`.
     * Lane Picker (0..3).
     * Summon button with legality verification and human-readable feedback.
     * Dual-player Floop buttons for P1 and P2.
     * Turn Zero controls: Tile placement buttons and Mulligan controls.
3. `test/arena_view_test.dart`:
   - Update widget assertions to verify P1/P2 dual tile badges, symmetrical console controls, and zero RenderFlex overflow on 1920x1080 and 800x600.
4. **Persistence**:
   - `logs/CYCLE_11_6_MODULE_2_UI_AGENT_EXECUTION_REPORT.md`

### Module 3: QA Agent (Gatekeeper & 4-Vector Verification)
1. Run `dart analyze --fatal-infos` and `flutter test`.
2. Audit all 4 vectors (Software, Math/Affinity Invariants, Resource/Viewport Hygiene, AST Headers).
3. **Persistence**:
   - `logs/CYCLE_11_6_FINAL_AUDIT_PROMOTION_VERDICT.md` with `QA_VERDICT: [PROMOTION GRANTED]` or `[PROMOTION DENIED]`.

---

## 5. Eval Harness Commands
```bash
dart analyze --fatal-infos
flutter test
```
