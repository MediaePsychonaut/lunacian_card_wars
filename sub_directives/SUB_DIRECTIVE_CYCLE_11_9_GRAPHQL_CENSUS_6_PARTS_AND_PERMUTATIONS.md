---
type: sub_directive
id: SUB_DIRECTIVE_CYCLE_11_9_GRAPHQL_CENSUS_6_PARTS_AND_PERMUTATIONS
cycle: 11.9
version: 1.0
status: dispatched
target_agents:
  - data_agent (CLI Scripting & GraphQL Data Architect)
  - qa_agent (Validation & Gatekeeper Architect)
author: der_tab (Director / Meta-Orchestrator)
created_at: 2026-09-19T11:25:00-06:00
system: lunacian_card_wars
tags:
  - graphql
  - ronin_census
  - axie_marketplace
  - 204_parts
  - 288_permutations
  - deterministic_csv
  - rate_limiting
---

# SUB-DIRECTIVE: Cycle 11.9 — On-Chain GraphQL Census of 6 Body Parts & Genetic Permutation Matrix

## 1. Problem Statement
To calibrate the deterministic combat balance algorithm (ATK, DEF, mana curves) and formalize individual Floop abilities, 12 Secret Floops, and innate combat passives, the engine requires empirical on-chain demographic data from the Ronin Network.

The biological universe of Axie Infinity comprises **6 anatomical slots** (Horns, Back, Tail, Mouth, Eyes, Ears) across **6 pure classes** (Beast, Aquatic, Plant, Bird, Bug, Reptile):
- **Horns (36 parts)**: Primary offensive determinants of base ATK, critical damage, and penetration.
- **Back (36 parts)**: Primary defensive determinants of base DEF, mitigation, and shields.
- **Mouth (24 parts)**: Active combat Floop abilities, steal, state alteration, and disruption.
- **Tail (36 parts)**: Tactical utility Floop abilities, mana manipulation, and acceleration.
- **Eyes (36 parts)**: Innate passive modifiers, accuracy, tactical vision, and Leader abilities.
- **Ears (36 parts)**: Elemental resistance modifiers, damage mitigation, and tactical utility.

This yields a master taxonomy of **204 physical anatomical parts**. We must query the Sky Mavis GraphQL API (`https://api-gateway.skymavis.com/graphql/axie-marketplace`) and persist two canonical CSV datasets in `assets/data/`:
1. `axie_part_stats_and_floops.csv`: Complete census of all 204 body parts with real minted populations.
2. `mouth_tail_permutation_floops.csv`: Population census of 288 specific simultaneous mouth-tail combinations (Pure lineages, Mech, Dusk, Dawn).

---

## 2. Acceptance Criteria (AC Matrix)

| ID | Criterion | Binary Metric |
|:---|:---|:---|
| **AC-01** | **Primary Dataset (`axie_part_stats_and_floops.csv`)**: Generated in `assets/data/`. Header: `Part_Name,Slot,Class,GraphQL_ID,Axie_Amount`. Exactly 204 data rows (36 Horns, 36 Backs, 36 Tails, 24 Mouths, 36 Eyes, 36 Ears) across 6 classes. Valid slug IDs (e.g. `mouth-nut-cracker`). `Axie_Amount` integer $\ge 0$. | PASS / FAIL |
| **AC-02** | **Secondary Dataset (`mouth_tail_permutation_floops.csv`)**: Generated in `assets/data/`. Header: `permutation_mouth_tail,Axie_amount`. Exactly 288 data rows: 144 pure lineages (24 per class x 6 classes) + 48 Mech (24 Bug x Beast, 24 Beast x Bug) + 48 Dusk (24 Reptile x Aquatic, 24 Aquatic x Reptile) + 48 Dawn (24 Plant x Bird, 24 Bird x Plant). Format `<mouthId>__<tailId>`. Valid integer counts. | PASS / FAIL |
| **AC-03** | **CLI Tool & Network Resilience**: Standalone Dart CLI script at `tool/census/fetch_axie_census.dart` executable via `dart run tool/census/fetch_axie_census.dart`. Reads `SKY_MAVIS_API_KEY` from environment or `secrets.env`. Includes 60ms-100ms request pacing and exponential retry backoff on HTTP 429 or network drop. | PASS / FAIL |
| **AC-04** | **Automated Integrity Verification**: Suite `test/census_data_integrity_test.dart` verifying physical file existence, line counts (205 lines in primary, 289 lines in secondary), slot/class balance, key format, non-empty/non-negative integers, and hyper-common threshold tests (>1,000,000 minted for serious, carrot, etc.). | PASS / FAIL |

---

## 3. Constraint Architecture & Technical Laws
1. **Credentials Isolation**: Never hardcode API keys in source code. Read from `Platform.environment['SKY_MAVIS_API_KEY']` or local uncommitted `secrets.env`. Ensure `.gitignore` guards secrets.
2. **Pure CLI Dependencies**: `tool/census/fetch_axie_census.dart` must depend exclusively on `dart:io`, `dart:convert`, and `package:http/http.dart`. Zero `package:flutter/*` imports.
3. **AST Standard Headers**: Standard 6-field English AST comment block on all created Dart files.
4. **Endpoint**: POST to `https://api-gateway.skymavis.com/graphql/axie-marketplace` with header `X-API-Key: <key>`.
5. **Topological Purity**: All code and generated data assets are written strictly to `C:\NeuroField\active_projects\lunacian_card_wars\`. Only Markdown specifications, sub-directives, and execution logs are mirrored to `C:\LatiCore\01_Projects\lunacian_card_wars\`. ZERO Dart code in LatiCore.

---

## 4. Modular Decomposition & Division of Labor

### Module 1: Canonical Part Catalog & CLI Extraction Tool (Data Agent)
**Target Files:**
1. `tool/census/fetch_axie_census.dart` (New):
   - Full static catalog of the 204 anatomical parts (Part Name, Slot, Class, GraphQL slug ID).
   - Generator for the 288 mouth-tail permutation pairs (Pure lineages, Mech, Dusk, Dawn).
   - HTTP GraphQL client communicating with `https://api-gateway.skymavis.com/graphql/axie-marketplace`.
   - Credential loader: checks `Platform.environment['SKY_MAVIS_API_KEY']`, falls back to parsing `secrets.env`.
   - Rate limiting (60ms-100ms throttle) and exponential retry logic on 429 / socket timeout.
   - Deterministic CSV writer saving:
     - `assets/data/axie_part_stats_and_floops.csv` (205 lines: 1 header + 204 parts)
     - `assets/data/mouth_tail_permutation_floops.csv` (289 lines: 1 header + 288 permutations)
2. Execution of extraction script:
   - Run `dart run tool/census/fetch_axie_census.dart` and confirm both datasets are fully populated with real on-chain numbers.
3. **Persistence**:
   - `logs/CYCLE_11_9_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md` (both workspace and LatiCore).

### Module 2: Integrity Verification & Quality Gate (QA Agent)
**Target Files:**
1. `test/census_data_integrity_test.dart` (New):
   - Test 1: File existence and line count (205 lines) of `assets/data/axie_part_stats_and_floops.csv`.
   - Test 2: Breakdown validation: 36 Horns, 36 Backs, 36 Tails, 24 Mouths, 36 Eyes, 36 Ears across all 6 classes.
   - Test 3: File existence and line count (289 lines) of `assets/data/mouth_tail_permutation_floops.csv`.
   - Test 4: Format validation: `<mouthId>__<tailId>`, no nulls, non-negative integer counts.
   - Test 5: Demographic density sanity checks (>1,000,000 for `mouth-serious`, `tail-carrot`, `mouth-nut-cracker`, `tail-nimo`).
2. Verification Execution:
   - Run `dart analyze --fatal-infos` on `tool/` and `test/`.
   - Run `flutter test test/census_data_integrity_test.dart` and full suite `flutter test`.
3. **Persistence**:
   - `logs/CYCLE_11_9_FINAL_AUDIT_PROMOTION_VERDICT.md` with `QA_VERDICT: [PROMOTION GRANTED]` (both workspace and LatiCore).
