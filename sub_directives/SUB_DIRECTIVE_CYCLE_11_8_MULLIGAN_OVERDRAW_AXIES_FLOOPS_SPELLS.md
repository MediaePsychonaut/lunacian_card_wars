---
type: sub_directive
id: SUB_DIRECTIVE_CYCLE_11_8_MULLIGAN_OVERDRAW_AXIES_FLOOPS_SPELLS
cycle: 11.8
version: 1.0
status: dispatched
target_agents:
  - data_agent (Engine & Domain Architect)
  - ui_agent (Presentation & Dual Cockpit Architect)
  - qa_agent (Validation & Gatekeeper Architect)
author: der_tab (Director / Meta-Orchestrator)
created_at: 2026-09-18T22:55:00-06:00
system: lunacian_card_wars
tags:
  - mulligan_hand_telemetry
  - overdraw_penalty
  - canonical_axie_factory
  - floop_ability_pipeline
  - spell_cards
  - dual_cockpit_upgrades
  - clean_architecture
  - riverpod
---

# SUB-DIRECTIVE: Cycle 11.8 — Mulligan Hand Telemetry, Overdraw Mechanics, Canonical Axies, Floops & Spells

## 1. Problem Statement
Cycle 11.7 established an 8-tile interleaved drafting FSM, early lethal clash aborts, and side-by-side cockpit telemetry. However, live testing and architectural auditing revealed critical mechanical omissions and interface blocks:
1. **Blind Mulligan Telemetry Bug**: During `TurnPhase.turnZeroMulligan`, both player cockpits display mulligan action buttons (`Keep Hand`, `Mulligan Selected`) but fail to render the player's 4-card opening hand. Players cannot evaluate card identities, costs, or affinities before deciding which cards to swap.
2. **Missing Hand Capacity Ceiling & Overdraw Penalty**: The engine lacks a hand size cap. Under Master Spec v3.1, hand size is strictly capped at **7 cards**. If a draw action occurs when holding 7 cards, the drawn card must be sent directly to the bottom of the player's draw pile (`deck`) without triggering a deck shuffle.
3. **Mulligan Deck Recovery & Reshuffle Omission**: Discarded mulligan cards must be returned to the draw pile, the draw pile must be deterministically shuffled (`Random(seed ^ roundNumber)`), and replacement cards must be drawn to restore the opening hand to exactly 4 cards.
4. **Generic Mock Cards vs. Canonical Axie Templates**: Combat decks generate randomized placeholder stats. The domain requires a canonical `AxieCardFactory` providing official starters (Buba, Olek, Puffy) and balanced archetype creatures across the 6 primary classes (Beast, Aquatic, Plant, Bird, Bug, Reptile) with deterministic HP, DEF, ATK, Pips, and affinities.
5. **Unstructured Floop Engine**: Floops are currently triggered as generic debug actions. Floops must be formalized as first-class domain entities (`FloopAbilityEntity`) with distinct names, mana costs (typically 1 to 2 mana), strict activation requirements (occupying unit alive, sufficient mana, once per round per lane), and deterministic execution hooks.
6. **Absence of Tactical Spells**: The engine only supports units and buildings. Canonical tabletop card battlers require instant one-shot actions (`SpellCardEntity`) that consume mana to deliver targeted direct damage, shields, stat modifications, or utility effects.

---

## 2. Acceptance Criteria (AC Matrix)

| ID | Criterion | Binary Metric |
|:---|:---|:---|
| **AC-01** | **Visible Opening Hand & Selective Mulligan**: In `turnZeroMulligan`, render 4-card opening hand with selection toggles. Provide `Mulligan Selected (X)` (enabled if $1 \le X \le 4$) and `Keep Entire Hand`. Upon confirmation, lock cockpit until opposing player confirms. | PASS / FAIL |
| **AC-02** | **Deterministic Mulligan Reinsertion & Shuffle**: `MulliganAction(player, selectedIds)` returns discarded cards to deck, shuffles deck deterministically (`Random(seed ^ roundNumber)`), and draws replacement cards up to 4. Transition to Round 1 when both complete. | PASS / FAIL |
| **AC-03** | **7-Card Hand Ceiling & Bottom-of-Deck Overdraw**: `PlayerState.maxHandCapacity = 7`. Drawing with 7 cards in hand moves drawn card to bottom of deck (`[...deck.sublist(1), drawnCard]`) without shuffle, logging formal telemetry. | PASS / FAIL |
| **AC-04** | **Canonical Axie Creature Factory**: Starters (Buba: Beast 3M/22A/18D, Olek: Plant 3M/16A/26D, Puffy: Aquatic 3M/20A/20D) and Class Archetypes (Little Owl: Bird 2M/18A/14D, Pocky Bug: Bug 2M/14A/20D, Tri Spikes: Reptile 4M/24A/24D) with floops. | PASS / FAIL |
| **AC-05** | **Formal Floop Ability Pipeline**: `FloopAbilityEntity` with `manaCost`, `targetRequirement`, `effectType`, `effectValue`. Track `bool hasFloopedThisRound` per `LaneSlot`. Guard validation (turn, alive, sufficient mana, once per round). Reset in round cleanup. | PASS / FAIL |
| **AC-06** | **Tactical Spells Pipeline**: `SpellCardEntity implements CombatCard` ("Potion of Vitality": 1M +6 DEF heal; "Star Shuriken": 2M 5 direct dmg; "Lunar Blessing": 2M +3 ATK). `PlaySpellAction` applies effect and moves card to graveyard. | PASS / FAIL |
| **AC-07** | **Standard 20-Card Deck Composition**: 12 Canonical Axies (2x each archetype) + 4 Tactical Buildings (Attack Totem, Defense Barricade, Vitality Shrine, 1 duplicate) + 4 Spells (2x Potion of Vitality, 1x Star Shuriken, 1x Lunar Blessing) + 4 Landscape Tiles. | PASS / FAIL |
| **AC-08** | **Side-by-Side Cockpit Telemetry Upgrades**: Mulligan cards display selection checkboxes; active combat displays `Hand: X/7`; chips show badges (`🐾`, `🏛️`, `✨`); Floop buttons display ability name and mana cost; Spell casting triggers enabled. | PASS / FAIL |
| **AC-09** | **Zero Regression & Full Verification**: `dart analyze --fatal-infos` yields 0 issues. `flutter test` achieves 100% pass rate. Responsive layout with 0 RenderFlex overflows and zero `.withOpacity()`. | PASS / FAIL |

---

## 3. Constraint Architecture & Technical Laws
1. **Pure Domain Boundary**: Pure Dart domain (`lib/src/domain/`). Zero `package:flutter/*` imports.
2. **Determinism**: Deterministic seeded RNG (`Random(seed)`). Zero unseeded randomizers or `DateTime.now()`.
3. **State Immutability**: All modifications via immutable copy methods.
4. **Flutter Web Hygiene**: Strictly zero `.withOpacity()`, 100% `.withValues(alpha: ...)`. Zero RenderFlex overflows across 1920x1080 and 800x600.
5. **AST Headers**: Standard 6-field English AST comment block on every modified/created Dart file.

---

## 4. Modular Decomposition & Division of Labor

### Module 1: Data / Engine Agent (Domain Models & Pure Engine Refactor)
**Target Files:**
1. `lib/src/domain/entities/combat/floop_ability_entity.dart` (New):
   - `enum FloopTargetType { self, laneEnemyUnit, opposingHero, alliedLaneUnit }`
   - `enum FloopEffectType { directDamage, buffAtk, restoreDef, debuffEnemyAtk }`
   - `class FloopAbilityEntity`: `id`, `name`, `manaCost`, `description`, `targetRequirement`, `effectType`, `effectValue`.
2. `lib/src/domain/entities/combat/spell_card_entity.dart` (New):
   - `enum SpellTargetType { alliedUnit, enemyUnit, enemyHero, laneSlot }`
   - `enum SpellEffectType { directDamage, grantDef, grantAtk, repairBuilding }`
   - `class SpellCardEntity implements CombatCard`: `id`, `name`, `manaCost`, `targetType`, `effectType`, `effectValue`, `description`.
   - Factory constructors: `potionOfVitality()`, `starShuriken()`, `lunarBlessing()`.
3. `lib/src/domain/services/axie_card_factory.dart` (New):
   - Canonical starter Axies: `bubaStarter()`, `olekStarter()`, `puffyStarter()`.
   - Canonical archetype Axies: `littleOwl()`, `pockyBug()`, `triSpikes()`.
   - Canonical 20-card deck generator: `createCanonicalDeck(String playerPrefix)`.
4. `lib/src/domain/entities/axie_card_entity.dart`:
   - Add `final FloopAbilityEntity? floop;`
   - Update constructor, `copyWith`, props, equality.
5. `lib/src/domain/entities/combat/board_lane_entity.dart`:
   - In `LaneSlot`: add `final bool hasFloopedThisRound;` (default `false`).
   - Update constructor, `copyWith`, props.
6. `lib/src/domain/entities/combat/player_state_entity.dart`:
   - Add `static const int maxHandCapacity = 7;`
7. `lib/src/domain/entities/combat/game_action.dart`:
   - `PlaySpellAction(PlayerId player, String cardInstanceId, int targetLaneIndex, [PlayerId? targetPlayer])`
   - Ensure `ActivateFloopAction` and `MulliganAction` align.
8. `lib/src/domain/services/combat_engine.dart`:
   - `initializeGame`: use canonical 20-card decks (12 Axies + 4 Buildings + 4 Spells).
   - `drawCard`: enforce 7-card hand cap. Overdraw puts drawn card to bottom of deck without shuffle, emits telemetry log.
   - `_mulligan`: return selected cards to deck, seeded deterministic shuffle, redraw to 4 cards.
   - `_playSpell`: validate mana, resolve effect (heal DEF capped at maxDef, direct damage, buff ATK), deduct mana, remove from hand, push to graveyard.
   - `_activateFloop`: validate mana, occupant alive, `!hasFloopedThisRound`. Deduct mana, apply effect, set `hasFloopedThisRound = true`.
   - `_startRound` / `_endRound`: reset `hasFloopedThisRound = false` for all lane slots.
9. `test/combat_engine_test.dart`:
   - Comprehensive unit test coverage for overdraw, mulligan shuffle, canonical stats, floops, spells, hand caps.
10. **Persistence**:
   - `logs/CYCLE_11_8_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md` (both workspace and LatiCore).

### Module 2: UI Agent (Presentation Layer & Dual Cockpit Upgrades)
**Target Files:**
1. `lib/src/presentation/controllers/combat_engine_controller.dart`:
   - Initialize with canonical 20-card decks from `AxieCardFactory`.
   - Add selective mulligan tracking: `Set<String> p1MulliganSelection`, `Set<String> p2MulliganSelection`.
   - Methods: `toggleMulliganCard(PlayerId player, String cardId)`, `confirmMulligan(PlayerId player)`, `castSpell(PlayerId player, String cardId, int laneIndex)`.
2. `lib/src/presentation/views/arena_view.dart`:
   - Mulligan Cockpit: render 4-card opening hand with checkboxes/toggle chips, `Confirm Mulligan (X cards)` and `Keep Entire Hand`. Lock cockpit on confirmation.
   - Active Combat Cockpit: `Hand: X/7 (Max: 7)`, chips displaying `🐾 Axie`, `🏛️ Building`, `✨ Spell`.
   - Floop Buttons: display ability name and cost (`Floop L0: Brutal Claw (1M)`), disable if insufficient mana or already used.
   - Spell Casting Buttons: `Cast Spell to Lane X` when spell card and lane are selected.
   - Strict responsive wrapping, 0 `.withOpacity()`, zero RenderFlex overflows.
3. `test/arena_view_test.dart`:
   - Widget tests verifying opening hand display in mulligan, dual cockpit gauges, floop and spell buttons, and overflow immunity.
4. **Persistence**:
   - `logs/CYCLE_11_8_MODULE_2_UI_AGENT_EXECUTION_REPORT.md` (both workspace and LatiCore).

### Module 3: QA Agent (Gatekeeper & 4-Vector Verification)
1. Run `flutter test` and verify 100% pass rate.
2. Run `dart analyze --fatal-infos` and verify 0 issues.
3. Audit 4-Vector Eval Harness.
4. **Persistence**:
   - `logs/CYCLE_11_8_FINAL_AUDIT_PROMOTION_VERDICT.md` with `QA_VERDICT: [PROMOTION GRANTED]` (both workspace and LatiCore).
