---
type: sub_directive
id: SUB_DIRECTIVE_CYCLE_11_5_FSM_REFACTOR_AND_STATE_TELEMETRY
cycle: 11.5
version: 1.0
status: dispatched
target_agents:
  - data_agent (Engine & Domain Architect)
  - ui_agent (Presentation & Telemetry Architect)
  - qa_agent (Validation & Gatekeeper Architect)
author: der_tab (Director / Meta-Orchestrator)
created_at: 2026-09-17T22:10:00-06:00
system: lunacian_card_wars
tags:
  - fsm_refactor
  - turn_zero_mulligan
  - state_telemetry_inspector
  - clean_architecture
  - riverpod
---

# SUB-DIRECTIVE: Cycle 11.5 — Deep FSM Refactor, Game Loop Master Spec Compliance & Raw State Telemetry

## 1. Problem Statement
Cycle 11 successfully implemented the baseline domain FSM and initial clash resolution, but introduced critical divergences from Master Spec v3.1:
1. Hero HP was hardcoded to 100 HP rather than the canonical 25 HP base pool, skewing combat pacing, lethal conditions, and trample arithmetic.
2. `TurnPhase.turnZero` was an inert stub lacking the canonical pre-game sequence: tile elemental affinity assignment, deterministic initiative determination, initial 4-card draw from 15-card decks, and deterministic single-pass mulligan.
3. The UI prematurely focused on hand rendering and mock card visuals instead of acting as a developer-grade State Graph & Telemetry Inspector.
4. Clash resolution requires structured, lane-by-lane inspectable telemetry: crit threshold check ($\lfloor \text{ATK} \times 1.25 \rfloor$), simultaneous cross, cascading trample (Unit $\rightarrow$ Building $\rightarrow$ Hero HP), and graveyard reaping.

---

## 2. Acceptance Criteria

| ID | Criterion | Binary Metric |
|:---|:---|:---|
| **AC-01** | **Canonical Domain Realignment & Mathematical Invariants**: Set `PlayerState.heroHp` and `maxHp` to exactly 25 HP. Enforce 15-card deck initializations. Implement Turn Zero with deterministic initiative, tile affinities assigned to lanes 0..3, and a `MulliganAction` enabling selective discard and redraw before transitioning to `roundStart`. | PASS / FAIL |
| **AC-02** | **Simultaneous 4-Lane Clash Engine Decomposition**: Refactor `resolveClashPhase` into discrete, deterministic steps: (1) Crit check with $\lfloor \text{ATK} \times 1.25 \rfloor$ when pips full and pip reset/increment; (2) Simultaneous mutual cross; (3) Cascading trample (`Unit DEF` $\rightarrow$ `Lane Building` with `armorReduction` $\rightarrow$ `Opposing Hero HP`); (4) Graveyard reaping of $\le 0$ DEF entities; (5) Terminal evaluation triggering `gameOver` if any `heroHp <= 0`. | PASS / FAIL |
| **AC-03** | **Reactive Micro-Window Enforcement**: `TurnPhase.p1ReactiveWindow` activates ONLY if P2 destroyed a P1 unit during `p2Turn` AND P1 has $\ge 1$ usable mana AND at least one playable reaction card in hand. If not met, engine skips directly to `clashPhase`. | PASS / FAIL |
| **AC-04** | **Arena View as FSM State Graph & Telemetry Inspector**: Redesign `ArenaView` into a developer cockpit: FSM Phase Breadcrumb / Status Header, 4-Lane Board Matrix Table (Affinity, Unit ATK/DEF, Pips, Floop status, Building HP), Player Telemetry Panels (25 HP gauges, Mana gauges, Hand list with instance IDs, Graveyard & Deck counts), Interactive Action Dispatcher Console (Advance Phase, Mulligan, Deploy Unit, Trigger Floop, Reset), and a live scrollable Action Log / Event Stream. | PASS / FAIL |
| **AC-05** | **Zero Regression & Expanded Test Harness**: `dart analyze --fatal-infos` reports 0 warnings/errors. `flutter test` achieves 100% pass rate across all suites, verifying 25 HP lifecycle, mulligan flow, tile affinities, cascading trample arithmetic, and reactive window guards. | PASS / FAIL |

---

## 3. Constraint Architecture

### 3.1. Technical & Stack Invariants
- **Stack**: Flutter Web 3.47+, Dart 3.x, Clean Architecture, Riverpod.
- **Purity & Determinism**: Zero unseeded `Random()` or `DateTime.now()` inside the domain engine.
- **English AST Headers**: All touched Dart files must start with the standard 6-field AST header (`[MODULE_NAME]`, `[SYSTEM]`, `[DOMAIN]`, `[INTENT]`, `[DEPENDENCIES]`, `[ARCHITECTURE]`).
- **Flutter Web Hygiene**: Strictly avoid `.withOpacity()`, utilizing `.withValues(alpha: ...)` for alpha blending. Zero RenderFlex overflows across viewports.
- **Architecture**: Strict layer separation — presentation must never mutate domain models directly; state flows through `CombatEngineController` via Riverpod.

---

## 4. Decomposition & Division of Labor

### Module 1: Data / Engine Agent (Domain Entities & Pure Engine Refactor)
**Target Files:**
1. `lib/src/domain/entities/combat/player_state_entity.dart`:
   - Set `heroHp` default and baseline to 25. Add `maxHp` (default 25) and `hasCompletedMulligan` (bool, default false).
2. `lib/src/domain/entities/combat/game_action.dart`:
   - Add `MulliganAction(PlayerId player, List<String> cardInstanceIdsToReplace)`.
3. `lib/src/domain/entities/combat/game_state.dart`:
   - Add `initiativePlayer` (PlayerId), `logs` (`List<String>`), and ensure immutable copyWith helpers.
4. `lib/src/domain/services/combat_engine.dart`:
   - Canonical 25 HP hero initialization with 15-card decks (4 drawn, 11 remaining in deck).
   - Turn Zero sequence with deterministic initiative, lane affinities, and `MulliganAction` handling (discard selected, redraw matching count from deck, set `hasCompletedMulligan`). Transition to `roundStart` when both mulligans are resolved.
   - Mana curve: Round 1 starts at 1 Max Mana, scaling $+1$ per round up to 10 ceiling.
   - Discrete clash resolution with event logging and cascading trample.
   - Strict `p1ReactiveWindow` guards.
5. `test/combat_engine_test.dart`:
   - Expanded test cases covering 25 HP lethal bounds, mulligan discard/redraw, trample cascading, and reactive window conditions.
6. **Persistence**:
   - `logs/CYCLE_11_5_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md`

### Module 2: UI Agent (Telemetry Inspector & Presentation Refactor)
**Target Files:**
1. `lib/src/presentation/controllers/combat_engine_controller.dart`:
   - Generate 15-card starter decks.
   - Expose methods: `dispatchAction`, `advancePhase`, `mulliganCard`, `playTestUnit`, `triggerFloop`, `resetBattle`.
2. `lib/src/presentation/views/arena_view.dart`:
   - Strip premature mock illustrations.
   - Implement FSM State Graph & Telemetry Inspector:
     - Header: Phase breadcrumb, round counter, active player, initiative owner.
     - Matrix Table: 4 columns with lane affinity, P2 slot telemetry, divider, P1 slot telemetry.
     - Player Telemetry Panels: 25 HP gauges, Mana gauges, Hand cards with instance IDs, Graveyard & Deck tallies.
     - Action Dispatcher: Advance phase, Mulligan controls, Deploy Unit buttons, Floop triggers, Reset.
     - Action Log: Scrollable event stream from `gameState.logs` / action history.
3. `test/arena_view_test.dart`:
   - Update widget test to verify telemetry inspector elements, 25 HP indicators, and zero RenderFlex overflow.
4. **Persistence**:
   - `logs/CYCLE_11_5_MODULE_2_UI_AGENT_EXECUTION_REPORT.md`

### Module 3: QA Agent (Gatekeeper & 4-Vector Promotion Audit)
1. Run `dart analyze --fatal-infos` and `flutter test`.
2. Audit the 4 vectors:
   - Vector A: Software verification (100% test pass, 0 fatal infos).
   - Vector B: Mathematical invariants (25 HP pool, 15 cards, crit $\lfloor \text{ATK} \times 1.25 \rfloor$, trample cascade).
   - Vector C: Resource & layout invariants (no `.withOpacity()`, zero RenderFlex overflow, clean immutable transitions).
   - Vector D: AST & clean architecture compliance.
3. **Persistence**:
   - `logs/CYCLE_11_5_FINAL_AUDIT_PROMOTION_VERDICT.md` with `QA_VERDICT: [PROMOTION GRANTED]` or `[PROMOTION DENIED]`.

---

## 5. Eval Harness Commands
```bash
dart analyze --fatal-infos
flutter test
```
