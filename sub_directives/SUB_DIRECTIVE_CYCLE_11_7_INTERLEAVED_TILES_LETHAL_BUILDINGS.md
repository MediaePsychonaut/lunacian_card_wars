---
type: sub_directive
id: SUB_DIRECTIVE_CYCLE_11_7_INTERLEAVED_TILES_LETHAL_BUILDINGS
cycle: 11.7
version: 1.0
status: dispatched
target_agents:
  - data_agent (Engine & Domain Architect)
  - ui_agent (Presentation & Dual Cockpit Architect)
  - qa_agent (Validation & Gatekeeper Architect)
author: der_tab (Director / Meta-Orchestrator)
created_at: 2026-09-18T01:45:00-06:00
system: lunacian_card_wars
tags:
  - interleaved_tile_drafting
  - priority_inversion
  - rotating_initiative
  - lethal_short_circuit
  - building_pipeline_and_auras
  - side_by_side_dual_cockpit
  - clean_architecture
  - riverpod
---

# SUB-DIRECTIVE: Cycle 11.7 — Interleaved Drafting, Dynamic Precedence, Early Lethal Resolution, Dual Cockpit & Lane Buildings

## 1. Problem Statement
While Cycle 11.6 established the canonical 8-landscape dual-tile topology, several crucial mechanical and interface rules diverge from competitive tabletop play and fluid developer testing:
1. **Batch vs. Interleaved Tile Drafting**: In Turn Zero, players do not place tiles in an alternating counter-drafting sequence. Players must alternate placements: `P_init -> P_react -> P_init -> ...` across all 8 slots.
2. **First-Mover Advantage Compensation**: The player who places the first landscape tile must concede Round 1 opening initiative to the second tile placer (`P_react`).
3. **Static Initiative Lock**: Priority must rotate between P1 and P2 at every round boundary.
4. **Unconditional Clash Calculation**: The engine currently resolves all 4 lanes even if opposing Hero HP hits 0 early (e.g. in Lane 0). The engine must short-circuit immediately upon lethal hero damage.
5. **Telemetry Friction**: Testing P1 vs P2 requires toggling dropdowns. A developer-grade side-by-side Symmetrical Dual Cockpit is required.
6. **Missing Building Pipeline in Decks**: Decks must expand to 20 cards (15 Axies + 5 Buildings) featuring persistent stat auras (+2 ATK, +5 DEF) and round start repair (8 DEF, capped at base DEF).

---

## 2. Acceptance Criteria

| ID | Criterion | Binary Metric |
|:---|:---|:---|
| **AC-01** | **Interleaved Turn Zero Landscape Drafting**: `turnZeroTilePlacement` enforces an 8-step alternating drafting sequence (`[P_init -> P_react x 4]`). `activePlayer` flips after each valid tile placement. Once all 8 tiles are locked, 4 cards are drawn for each player and phase transitions to `turnZeroMulligan`. | PASS / FAIL |
| **AC-02** | **Turn Zero Drafting Compensation & Round 1 Priority Inversion**: `GameState` tracks `firstTilePlacer`. The second tile placer (`P_react`) is awarded Round 1 opening initiative (`initiativePlayer = P_react`), starting Round 1 in `TurnPhase.p2Turn` (if P2 was `P_react`) or `TurnPhase.p1Turn` (if P1 was `P_react`). | PASS / FAIL |
| **AC-03** | **Dynamic Round-by-Round Initiative Alternation**: `initiativePlayer` systematically flips each round boundary (`roundEnd -> roundStart`). Turn sequence honors `P_first -> P_second -> (reactive window) -> clashPhase`. | PASS / FAIL |
| **AC-04** | **Lane-by-Lane Lethal Short-Circuit in Clash Phase**: `resolveClashPhase` evaluates lanes sequentially (0 to 3). If any Hero drops to $\le 0$ HP in Lane $k$, subsequent lanes $> k$ are immediately aborted, winner is assigned, and phase transitions to `TurnPhase.gameOver`. Mutual knockout in Lane $k$ triggers a draw state (`winner = null`) and aborts remaining lanes. | PASS / FAIL |
| **AC-05** | **20-Card Decks with 5 Tactical Building Cards & Auras**: Expand decks to 20 cards (15 Axies + 5 Buildings). Introduce `BuildingCardEntity` (`atk_totem`: +2 ATK aura, `def_barricade`: +5 DEF aura, `vitality_shrine`: restores 8 DEF at round start, capped at base DEF). Implement `PlayBuildingAction`. Integrate auras dynamically into effective unit ATK/DEF calculations. | PASS / FAIL |
| **AC-06** | **Symmetrical Side-by-Side Dual-Player Telemetry Cockpit**: Redesign `ArenaView` action console to render Player 1 and Player 2 cockpits simultaneously side-by-side. Display Lane Building status (Name, HP, Armor, Aura) in Board Matrix. Enclose cockpits in responsive scroll containers to prevent RenderFlex overflow. | PASS / FAIL |
| **AC-07** | **Zero Regression & Automated Verification**: `dart analyze --fatal-infos` yields 0 issues. `flutter test` achieves 100% pass rate with targeted unit tests in `test/combat_engine_test.dart` and widget tests in `test/arena_view_test.dart`. | PASS / FAIL |

---

## 3. Constraint Architecture

### 3.1. Technical & Stack Invariants
- **Stack**: Flutter Web 3.47+, Dart 3.x, Clean Architecture, Riverpod.
- **Purity & Determinism**: Zero unseeded `Random()` or `DateTime.now()` in domain logic. Pure state immutability via `copyWith`.
- **English AST Headers**: All created or modified Dart files must start with the standard 6-field AST header.
- **Flutter Web Hygiene**: Strictly zero `.withOpacity()`; use `.withValues(alpha: ...)`. Zero RenderFlex overflows across desktop (1920x1080) and compact (800x600) viewports.
- **Decoupling**: Domain models and services must NEVER import Flutter UI packages.

---

## 4. Decomposition & Division of Labor

### Module 1: Data / Engine Agent (Domain Models & Pure Engine Refactor)
**Target Files:**
1. `lib/src/domain/entities/combat/building_card_entity.dart` (New):
   - `BuildingEffectType { attackAura, defenseAura, roundStartRepair }`
   - `BuildingCardEntity implements CombatCard`: `id`, `name`, `manaCost`, `maxHp`, `armorReduction`, `effectType`, `effectValue`.
   - Helper factory constructors for prototypes: `attackTotem()`, `defenseBarricade()`, `vitalityShrine()`.
2. `lib/src/domain/entities/combat/combat_card.dart` (New or Interface):
   - `abstract class CombatCard { String get id; String get name; int get manaCost; }`
   - Ensure `AxieCardEntity` and `BuildingCardEntity` implement `CombatCard`.
3. `lib/src/domain/entities/combat/board_building_entity.dart`:
   - Add `effectType` (`BuildingEffectType?`) and `effectValue` (`int`).
   - Factory `BoardBuildingEntity.fromCard(BuildingCardEntity card, {required String instanceId})`.
4. `lib/src/domain/entities/combat/game_action.dart`:
   - `PlayBuildingAction(PlayerId player, int laneIndex, String cardInstanceId)` (or `BuildingCardEntity building`).
   - `PassTurnAction(PlayerId player)` (or existing `PassPhaseAction`).
5. `lib/src/domain/entities/combat/player_state_entity.dart`:
   - Hand and deck typed as `List<CombatCard>` (or `List<dynamic>`).
   - Initial deck size: exactly 20 cards (15 Axies + 5 Buildings).
6. `lib/src/domain/entities/combat/game_state.dart`:
   - Add `PlayerId? firstTilePlacer`.
   - Retain `PlayerId initiativePlayer`.
7. `lib/src/domain/services/combat_engine.dart`:
   - `initializeGame`: Sets 20-card decks, initial active player for tile drafting, sets `firstTilePlacer = activePlayer`.
   - Interleaved tile placement in `reduce(PlaceTileAction)`: toggles `activePlayer` after each valid tile placement until 8 tiles are placed, then draws 4 cards each and transitions to `turnZeroMulligan`.
   - `_prepareRoundOne`: sets `initiativePlayer = (firstTilePlacer == PlayerId.p1) ? PlayerId.p2 : PlayerId.p1`, `activePlayer = initiativePlayer`, phase = `p2Turn` or `p1Turn`.
   - `reduce(PlayBuildingAction)`: validates mana and empty building slot, deploys building, deducts mana.
   - Dynamic Auras: `getEffectiveAtk(lane, player)`, `getEffectiveDef(lane, player)`.
   - Round start repair hook: restore up to 8 DEF (capped at unit's base DEF) on lanes with `roundStartRepair`.
   - `resolveClashPhase`: Sequential lane loop with immediate lethal break if any Hero $\le 0$ HP.
   - Round-to-round initiative rotation: `nextInitiative = (initiativePlayer == PlayerId.p1) ? PlayerId.p2 : PlayerId.p1`.
8. `test/combat_engine_test.dart`:
   - Unit tests covering all 8 criteria in AC-07.
9. **Persistence**:
   - `logs/CYCLE_11_7_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md`

### Module 2: UI Agent (Presentation Layer & Side-by-Side Dual Cockpit)
**Target Files:**
1. `lib/src/presentation/controllers/combat_engine_controller.dart`:
   - Update `_generateTestDeck`: 15 Axies + 5 Buildings (Attack Totem, Defense Barricade, Vitality Shrine, + 2 copies).
   - Independent selection states for P1 and P2 (`selectedP1CardId`, `selectedP1Lane`, `selectedP2CardId`, `selectedP2Lane`).
   - Expose methods: `deployUnit(player, cardId, lane)`, `deployBuilding(player, cardId, lane)`, `passTurn(player)`, `triggerFloop(player, lane)`.
2. `lib/src/presentation/views/arena_view.dart`:
   - Redesign action console into Symmetrical Side-by-Side Dual Cockpit (Left: Player 1, Right: Player 2).
   - Display Lane Building status (Name, HP, Armor, Aura) in Board Matrix.
   - Responsive scrolling (`SingleChildScrollView`) preventing RenderFlex overflow on 1920x1080 and 800x600.
3. `test/arena_view_test.dart`:
   - Update widget tests verifying dual cockpit columns, building rendering, and overflow immunity.
4. **Persistence**:
   - `logs/CYCLE_11_7_MODULE_2_UI_AGENT_EXECUTION_REPORT.md`

### Module 3: QA Agent (Gatekeeper & 4-Vector Verification)
1. Run `dart analyze --fatal-infos` and `flutter test`.
2. 4-Vector Eval Harness audit (Software, Math/Aura Invariants, Viewport Hygiene, AST Headers).
3. **Persistence**:
   - `logs/CYCLE_11_7_FINAL_AUDIT_PROMOTION_VERDICT.md` with `QA_VERDICT: [PROMOTION GRANTED]` or `[PROMOTION DENIED]`.

---

## 5. Eval Harness Commands
```bash
dart analyze --fatal-infos
flutter test
```
