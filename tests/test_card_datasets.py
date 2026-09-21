# ===============================================================================
# [MODULE_NAME]: test_card_datasets.py
# [SYSTEM]: lunacian_card_wars
# [DOMAIN]: Test / Data Integration & Schema Verification
# [INTENT]: Integration test suite for Cycle 12 Card Engine master datasets, verifying schemas, stat conservation, power curve z-scores, referential integrity, and resource benchmarks.
# [DEPENDENCIES]: pytest, os, csv, time, math
# [ARCHITECTURE]: Deterministic Data Integration & Quality Assurance Harness
# ===============================================================================

import os
import csv
import math
import time
import pytest

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GENERATED_DIR = os.path.join(WORKSPACE_ROOT, "assets", "data", "generated")

FLOOPS_CSV = os.path.join(GENERATED_DIR, "axie_part_floops_matrix.csv")
STRUCTURES_CSV = os.path.join(GENERATED_DIR, "structures_master.csv")
SPELLS_CSV = os.path.join(GENERATED_DIR, "spells_master.csv")


def load_csv(path):
    assert os.path.exists(path), f"File missing: {path}"
    with open(path, "r", encoding="utf-8") as f:
        reader = list(csv.DictReader(f))
    with open(path, "r", encoding="utf-8") as f:
        raw_lines = [l for l in f if l.strip()]
    return reader, len(raw_lines)


class TestCardEngineDatasets:

    def test_01_ingestion_and_schema_validation(self):
        """Test 1: Ingestion and schema validation of all 3 CSV files in assets/data/generated/."""
        # 1. axie_part_floops_matrix.csv
        floops, floops_lines = load_csv(FLOOPS_CSV)
        assert floops_lines == 73, f"Expected 73 lines in floops matrix, got {floops_lines}"
        assert len(floops) == 72, f"Expected 72 data rows, got {len(floops)}"

        expected_floops_cols = [
            "part_id", "part_type", "class", "part_name", "floop_id", "floop_name",
            "activation_mana_cost", "atk_bias_shift", "def_bias_shift", "effect_type",
            "base_value", "scaling_formula", "conditional_rule", "target_scope",
            "is_secret", "secret_combo_req", "archetype_tag", "card_art_asset_id"
        ]
        assert list(floops[0].keys()) == expected_floops_cols, "Column mismatch in floops matrix"

        for row in floops:
            for col in expected_floops_cols:
                assert row[col] is not None and row[col] != "", f"Empty value at {row['part_id']}.{col}"
            assert row["part_type"] in ["mouth", "tail", "secret_combo"]
            int(row["activation_mana_cost"])
            int(row["atk_bias_shift"])
            int(row["def_bias_shift"])
            int(row["base_value"])
            int(row["is_secret"])

        # 2. structures_master.csv
        structures, str_lines = load_csv(STRUCTURES_CSV)
        assert str_lines == 31, f"Expected 31 lines in structures_master, got {str_lines}"
        assert len(structures) == 30, f"Expected 30 data rows, got {len(structures)}"

        expected_str_cols = [
            "structure_id", "name", "landscape", "mana_cost", "base_hp",
            "passive_effect_type", "effect_value", "scaling_formula",
            "activation_trigger", "target_scope", "lore_description", "card_art_asset_id"
        ]
        assert list(structures[0].keys()) == expected_str_cols, "Column mismatch in structures_master"

        valid_landscapes = {"corn_fields", "blue_plains", "nice_lands", "sandy_lands", "useless_swamp", "rainbow"}
        valid_triggers = {"PASSIVE", "ON_DESTROY", "ON_SUMMON", "START_OF_TURN", "ON_FLOOP"}
        for row in structures:
            for col in expected_str_cols:
                assert row[col] is not None and row[col] != "", f"Empty value at {row['structure_id']}.{col}"
            assert row["landscape"] in valid_landscapes, f"Invalid landscape: {row['landscape']}"
            assert row["activation_trigger"] in valid_triggers, f"Invalid trigger: {row['activation_trigger']}"
            int(row["mana_cost"])
            int(row["base_hp"])
            int(row["effect_value"])

        # 3. spells_master.csv
        spells, spl_lines = load_csv(SPELLS_CSV)
        assert spl_lines == 50, f"Expected 50 lines in spells_master, got {spl_lines}"
        assert len(spells) == 49, f"Expected 49 data rows, got {len(spells)}"

        expected_spl_cols = [
            "spell_id", "name", "landscape_affinity", "mana_cost", "spell_type",
            "effect_type", "base_value", "scaling_rule", "target_scope",
            "turn_duration", "lore_description", "card_art_asset_id"
        ]
        assert list(spells[0].keys()) == expected_spl_cols, "Column mismatch in spells_master"

        valid_affinities = {"corn_fields", "blue_plains", "nice_lands", "sandy_lands", "useless_swamp", "universal"}
        valid_spell_types = {"TARGETED", "GLOBAL", "INSTANT"}
        for row in spells:
            for col in expected_spl_cols:
                assert row[col] is not None and row[col] != "", f"Empty value at {row['spell_id']}.{col}"
            assert row["landscape_affinity"] in valid_affinities, f"Invalid affinity: {row['landscape_affinity']}"
            assert row["spell_type"] in valid_spell_types, f"Invalid spell type: {row['spell_type']}"
            int(row["mana_cost"])
            int(row["base_value"])
            int(row["turn_duration"])

    def test_02_mathematical_balance_and_stat_conservation(self):
        """Test 2: Mathematical Balance & Stat Conservation Law.
        - For every row in axie_part_floops_matrix.csv, assert atk_bias_shift + def_bias_shift == 0.
        - Assert 0 <= activation_mana_cost <= 3.
        - Power curve z-score variance check: assert power envelopes do not deviate > 2.0 sigma.
        """
        floops, _ = load_csv(FLOOPS_CSV)

        for row in floops:
            atk_shift = int(row["atk_bias_shift"])
            def_shift = int(row["def_bias_shift"])
            mana_cost = int(row["activation_mana_cost"])

            # Stat Conservation Law (AC-2)
            assert atk_shift + def_shift == 0, (
                f"Stat Conservation Law violated for {row['part_id']}: "
                f"atk_shift ({atk_shift}) + def_shift ({def_shift}) != 0"
            )

            # Activation mana bounds
            assert 0 <= mana_cost <= 3, (
                f"Mana cost out of bounds for {row['part_id']}: {mana_cost}"
            )

        # Power curve z-score variance check:
        # Standard parts power envelope grouped by pure class
        pure_classes = ["beast", "aqua", "plant", "bird", "bug", "reptile"]
        class_power_totals = []

        for cls in pure_classes:
            class_parts = [r for r in floops if r["class"] == cls and int(r["is_secret"]) == 0]
            assert len(class_parts) == 10, f"Expected 10 standard parts for class {cls}, got {len(class_parts)}"

            values = [float(r["base_value"]) for r in class_parts]
            mean_val = sum(values) / len(values)
            std_val = math.sqrt(sum((v - mean_val) ** 2 for v in values) / len(values))

            # Within-class part power z-scores must not deviate > 2.0 sigma
            for r in class_parts:
                val = float(r["base_value"])
                z_score = abs(val - mean_val) / std_val if std_val > 0 else 0.0
                assert z_score <= 2.0, (
                    f"Power envelope outlier in class {cls} for {r['part_id']}: "
                    f"val={val}, mean={mean_val:.2f}, std={std_val:.2f}, z={z_score:.2f} > 2.0 sigma"
                )

            class_power_totals.append(sum(values))

        # Across-class power envelope z-score variance:
        # Total class power budget across all 6 pure archetypes
        mean_class_power = sum(class_power_totals) / len(class_power_totals)
        std_class_power = math.sqrt(
            sum((cp - mean_class_power) ** 2 for cp in class_power_totals) / len(class_power_totals)
        )

        for cls, cp in zip(pure_classes, class_power_totals):
            z_score = abs(cp - mean_class_power) / std_class_power if std_class_power > 0 else 0.0
            assert z_score <= 2.0, (
                f"Class aggregate power envelope for {cls} ({cp}) deviates by "
                f"z={z_score:.2f} > 2.0 sigma (mean={mean_class_power:.1f}, std={std_class_power:.1f})"
            )

    def test_03_foreign_key_and_secret_permutation_referential_integrity(self):
        """Test 3: Foreign Key & Secret Permutation Referential Integrity.
        - Verify all 12 secret combos (is_secret == 1) declare secret_combo_req in format part_id_mouth+part_id_tail.
        - Assert that every referenced part_id in secret_combo_req exists in part_id of the same file (0 dangling foreign keys).
        - Verify 6 Pure Synergies and 6 Hybrid Synergies.
        """
        floops, _ = load_csv(FLOOPS_CSV)
        all_part_ids = {r["part_id"] for r in floops}
        standard_part_ids = {r["part_id"] for r in floops if int(r["is_secret"]) == 0}

        secret_combos = [r for r in floops if int(r["is_secret"]) == 1]
        assert len(secret_combos) == 12, f"Expected exactly 12 secret combos, found {len(secret_combos)}"

        pure_combos = []
        hybrid_combos = []

        for sec in secret_combos:
            req = sec["secret_combo_req"]
            assert "+" in req, f"Secret combo req must have format mouth+tail: {req}"
            parts = req.split("+")
            assert len(parts) == 2, f"Expected 2 parts in secret_combo_req: {req}"
            mouth_id, tail_id = parts[0].strip(), parts[1].strip()

            # Referential integrity: 0 dangling foreign keys
            assert mouth_id in standard_part_ids, f"Dangling mouth FK {mouth_id} in {sec['part_id']}"
            assert tail_id in standard_part_ids, f"Dangling tail FK {tail_id} in {sec['part_id']}"

            sec_id = sec["part_id"]
            sec_num = int(sec_id.split("_")[1])
            if 1 <= sec_num <= 6:
                pure_combos.append(sec)
            else:
                hybrid_combos.append(sec)

        # Verify 6 Pure Synergies (Beast, Aqua, Plant, Reptile, Bug, Bird)
        assert len(pure_combos) == 6, f"Expected 6 pure combos, got {len(pure_combos)}"
        pure_classes = {c["class"] for c in pure_combos}
        assert pure_classes == {"beast", "aqua", "plant", "reptile", "bug", "bird"}

        # Verify 6 Hybrid Synergies (2 Melee Beast x Bug, 2 Control Plant x Reptile, 2 Tempo Aqua x Bird)
        assert len(hybrid_combos) == 6, f"Expected 6 hybrid combos, got {len(hybrid_combos)}"
        hybrid_classes = [c["class"] for c in hybrid_combos]
        assert hybrid_classes.count("mech") == 2, "Expected 2 Mech (Beast x Bug) combos"
        assert hybrid_classes.count("dusk") == 2, "Expected 2 Dusk (Plant x Reptile) combos"
        assert hybrid_classes.count("dawn") == 2, "Expected 2 Dawn (Aqua x Bird) combos"

        # Check hybrid pairs
        sec_07 = next(s for s in hybrid_combos if s["part_id"] == "sec_07")
        sec_08 = next(s for s in hybrid_combos if s["part_id"] == "sec_08")
        assert sec_07["secret_combo_req"] == "b_mouth_01+bg_tail_01"  # Beast mouth + Bug tail
        assert sec_08["secret_combo_req"] == "bg_mouth_01+b_tail_01"  # Bug mouth + Beast tail

        sec_09 = next(s for s in hybrid_combos if s["part_id"] == "sec_09")
        sec_10 = next(s for s in hybrid_combos if s["part_id"] == "sec_10")
        assert sec_09["secret_combo_req"] == "pl_mouth_01+rp_tail_01"  # Plant mouth + Reptile tail
        assert sec_10["secret_combo_req"] == "rp_mouth_01+pl_tail_01"  # Reptile mouth + Plant tail

        sec_11 = next(s for s in hybrid_combos if s["part_id"] == "sec_11")
        sec_12 = next(s for s in hybrid_combos if s["part_id"] == "sec_12")
        assert sec_11["secret_combo_req"] == "aq_mouth_01+bd_tail_01"  # Aqua mouth + Bird tail
        assert sec_12["secret_combo_req"] == "bd_mouth_01+aq_tail_01"  # Bird mouth + Aqua tail

    def test_04_resource_and_performance_micro_benchmark(self):
        """Test 4: Resource & Performance Micro-benchmark.
        - Total combined size of the 3 CSV files < 500 KB.
        - Parsing time for all 3 datasets < 15 ms.
        """
        # 1. Total size check
        size_floops = os.path.getsize(FLOOPS_CSV)
        size_str = os.path.getsize(STRUCTURES_CSV)
        size_spl = os.path.getsize(SPELLS_CSV)
        total_size_bytes = size_floops + size_str + size_spl
        total_size_kb = total_size_bytes / 1024.0

        assert total_size_kb < 500.0, (
            f"Total dataset size ({total_size_kb:.2f} KB) exceeds 500 KB limit"
        )

        # 2. Parsing time benchmark
        # Measure warm parsing across multiple iterations for stability
        iterations = 10
        start = time.perf_counter()
        for _ in range(iterations):
            f_data, _ = load_csv(FLOOPS_CSV)
            s_data, _ = load_csv(STRUCTURES_CSV)
            p_data, _ = load_csv(SPELLS_CSV)
            assert len(f_data) == 72
            assert len(s_data) == 30
            assert len(p_data) == 49
        elapsed_total = time.perf_counter() - start
        avg_elapsed_ms = (elapsed_total / iterations) * 1000.0

        assert avg_elapsed_ms < 15.0, (
            f"Average dataset parsing time ({avg_elapsed_ms:.2f} ms) exceeds 15 ms limit"
        )
