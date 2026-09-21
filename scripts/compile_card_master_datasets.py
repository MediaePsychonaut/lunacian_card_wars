#!/usr/bin/env python3
# ===============================================================================
# [MODULE_NAME]: compile_card_master_datasets.py
# [SYSTEM]: lunacian_card_wars
# [DOMAIN]: Data / ETL Pipeline
# [INTENT]: Compiles raw on-chain demographic census and Lunacia card data into normalized master game engine datasets for Axie Floops, Structures, and Spells.
# [DEPENDENCIES]: csv, os, sys, typing
# [ARCHITECTURE]: Standalone Deterministic ETL Script
# ===============================================================================

import csv
import os
import sys
from typing import List, Dict, Any

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(WORKSPACE_ROOT, "assets", "data")
OUTPUT_DIR = os.path.join(DATA_DIR, "generated")

PARTS_CENSUS_PATH = os.path.join(DATA_DIR, "axie_part_stats_and_floops.csv")
PERMUTATIONS_CENSUS_PATH = os.path.join(DATA_DIR, "mouth_tail_permutation_floops.csv")
ADVENTURE_CARDS_PATH = os.path.join(DATA_DIR, "adventrue_time_cards.csv")

OUTPUT_FLOOPS_PATH = os.path.join(OUTPUT_DIR, "axie_part_floops_matrix.csv")
OUTPUT_STRUCTURES_PATH = os.path.join(OUTPUT_DIR, "structures_master.csv")
OUTPUT_SPELLS_PATH = os.path.join(OUTPUT_DIR, "spells_master.csv")

# 12 Secret Combos Definition (Section 6 of Directive)
SECRET_COMBOS = [
    {
        "part_id": "sec_01",
        "part_type": "secret_combo",
        "class": "beast",
        "part_name": "Pure Beast Secret Combo",
        "floop_id": "flp_sec_01",
        "floop_name": "Savage Rampage",
        "activation_mana_cost": 2,
        "atk_bias_shift": 20,
        "def_bias_shift": -20,
        "effect_type": "DAMAGE",
        "base_value": 40,
        "scaling_formula": "BASE + (AXIE_MANA - 1) * 25",
        "conditional_rule": "NONE",
        "target_scope": "OPPOSING_LANE",
        "is_secret": 1,
        "secret_combo_req": "b_mouth_01+b_tail_01",
        "archetype_tag": "Corn_Aggro",
        "card_art_asset_id": "art_sec_savage_rampage",
    },
    {
        "part_id": "sec_02",
        "part_type": "secret_combo",
        "class": "aqua",
        "part_name": "Pure Aqua Secret Combo",
        "floop_id": "flp_sec_02",
        "floop_name": "Tidal Vortex",
        "activation_mana_cost": 1,
        "atk_bias_shift": -10,
        "def_bias_shift": 10,
        "effect_type": "BOUNCE",
        "base_value": 1,
        "scaling_formula": "NONE",
        "conditional_rule": "TARGET_MANA <= AXIE_MANA",
        "target_scope": "OPPOSING_LANE",
        "is_secret": 1,
        "secret_combo_req": "aq_mouth_01+aq_tail_01",
        "archetype_tag": "Blue_Tempo",
        "card_art_asset_id": "art_sec_tidal_vortex",
    },
    {
        "part_id": "sec_03",
        "part_type": "secret_combo",
        "class": "plant",
        "part_name": "Pure Plant Secret Combo",
        "floop_id": "flp_sec_03",
        "floop_name": "Yggdrasil Fortress",
        "activation_mana_cost": 2,
        "atk_bias_shift": -25,
        "def_bias_shift": 25,
        "effect_type": "SHIELD",
        "base_value": 50,
        "scaling_formula": "BASE + (AXIE_MANA - 1) * 30",
        "conditional_rule": "NONE",
        "target_scope": "SELF",
        "is_secret": 1,
        "secret_combo_req": "pl_mouth_01+pl_tail_01",
        "archetype_tag": "Nice_Sustain",
        "card_art_asset_id": "art_sec_yggdrasil_fortress",
    },
    {
        "part_id": "sec_04",
        "part_type": "secret_combo",
        "class": "reptile",
        "part_name": "Pure Reptile Secret Combo",
        "floop_id": "flp_sec_04",
        "floop_name": "Gorgon Gaze",
        "activation_mana_cost": 1,
        "atk_bias_shift": -15,
        "def_bias_shift": 15,
        "effect_type": "DEBUFF_ATK",
        "base_value": 20,
        "scaling_formula": "BASE + (AXIE_MANA - 1) * 10",
        "conditional_rule": "TARGET_MANA <= AXIE_MANA",
        "target_scope": "OPPOSING_LANE",
        "is_secret": 1,
        "secret_combo_req": "rp_mouth_01+rp_tail_01",
        "archetype_tag": "Sandy_Attrition",
        "card_art_asset_id": "art_sec_gorgon_gaze",
    },
    {
        "part_id": "sec_05",
        "part_type": "secret_combo",
        "class": "bug",
        "part_name": "Pure Bug Secret Combo",
        "floop_id": "flp_sec_05",
        "floop_name": "Swarm Havoc",
        "activation_mana_cost": 1,
        "atk_bias_shift": 10,
        "def_bias_shift": -10,
        "effect_type": "DISCARD",
        "base_value": 15,
        "scaling_formula": "BASE + (AXIE_MANA - 1) * 10",
        "conditional_rule": "NONE",
        "target_scope": "ANY_LANE_ENEMY",
        "is_secret": 1,
        "secret_combo_req": "bg_mouth_01+bg_tail_01",
        "archetype_tag": "Swamp_Disruption",
        "card_art_asset_id": "art_sec_swarm_havoc",
    },
    {
        "part_id": "sec_06",
        "part_type": "secret_combo",
        "class": "bird",
        "part_name": "Pure Bird Secret Combo",
        "floop_id": "flp_sec_06",
        "floop_name": "Celestial Dive",
        "activation_mana_cost": 2,
        "atk_bias_shift": 30,
        "def_bias_shift": -30,
        "effect_type": "BURST_DAMAGE",
        "base_value": 45,
        "scaling_formula": "BASE + (AXIE_MANA - 1) * 20",
        "conditional_rule": "NONE",
        "target_scope": "OPPOSING_HERO",
        "is_secret": 1,
        "secret_combo_req": "bd_mouth_01+bd_tail_01",
        "archetype_tag": "Swamp_Backdoor",
        "card_art_asset_id": "art_sec_celestial_dive",
    },
    {
        "part_id": "sec_07",
        "part_type": "secret_combo",
        "class": "mech",
        "part_name": "Hybrid Beast Bug Secret Combo",
        "floop_id": "flp_sec_07",
        "floop_name": "Primal Ravage",
        "activation_mana_cost": 2,
        "atk_bias_shift": 15,
        "def_bias_shift": -15,
        "effect_type": "DAMAGE",
        "base_value": 35,
        "scaling_formula": "BASE + (AXIE_MANA - 1) * 20",
        "conditional_rule": "NONE",
        "target_scope": "OPPOSING_LANE",
        "is_secret": 1,
        "secret_combo_req": "b_mouth_01+bg_tail_01",
        "archetype_tag": "Melee_Carnage",
        "card_art_asset_id": "art_sec_primal_ravage",
    },
    {
        "part_id": "sec_08",
        "part_type": "secret_combo",
        "class": "mech",
        "part_name": "Hybrid Bug Beast Secret Combo",
        "floop_id": "flp_sec_08",
        "floop_name": "Parasitic Frenzy",
        "activation_mana_cost": 1,
        "atk_bias_shift": 10,
        "def_bias_shift": -10,
        "effect_type": "BUFF_ATK",
        "base_value": 20,
        "scaling_formula": "BASE + (AXIE_MANA - 1) * 10",
        "conditional_rule": "NONE",
        "target_scope": "SELF",
        "is_secret": 1,
        "secret_combo_req": "bg_mouth_01+b_tail_01",
        "archetype_tag": "Disruptive_Aggro",
        "card_art_asset_id": "art_sec_parasitic_frenzy",
    },
    {
        "part_id": "sec_09",
        "part_type": "secret_combo",
        "class": "dusk",
        "part_name": "Hybrid Plant Reptile Secret Combo",
        "floop_id": "flp_sec_09",
        "floop_name": "Thorny Brambles",
        "activation_mana_cost": 1,
        "atk_bias_shift": -20,
        "def_bias_shift": 20,
        "effect_type": "THORNS_BUFF",
        "base_value": 100,
        "scaling_formula": "NONE",
        "conditional_rule": "NONE",
        "target_scope": "SELF",
        "is_secret": 1,
        "secret_combo_req": "pl_mouth_01+rp_tail_01",
        "archetype_tag": "Control_Spikes",
        "card_art_asset_id": "art_sec_thorny_brambles",
    },
    {
        "part_id": "sec_10",
        "part_type": "secret_combo",
        "class": "dusk",
        "part_name": "Hybrid Reptile Plant Secret Combo",
        "floop_id": "flp_sec_10",
        "floop_name": "Noxious Spores",
        "activation_mana_cost": 2,
        "atk_bias_shift": -10,
        "def_bias_shift": 10,
        "effect_type": "POISON",
        "base_value": 3,
        "scaling_formula": "BASE + (AXIE_MANA - 1) * 1",
        "conditional_rule": "NONE",
        "target_scope": "OPPOSING_LANE",
        "is_secret": 1,
        "secret_combo_req": "rp_mouth_01+pl_tail_01",
        "archetype_tag": "Control_Attrition",
        "card_art_asset_id": "art_sec_noxious_spores",
    },
    {
        "part_id": "sec_11",
        "part_type": "secret_combo",
        "class": "dawn",
        "part_name": "Hybrid Aqua Bird Secret Combo",
        "floop_id": "flp_sec_11",
        "floop_name": "Squall Ambush",
        "activation_mana_cost": 1,
        "atk_bias_shift": 0,
        "def_bias_shift": 0,
        "effect_type": "SWAP_LANE",
        "base_value": 0,
        "scaling_formula": "NONE",
        "conditional_rule": "NONE",
        "target_scope": "SELF",
        "is_secret": 1,
        "secret_combo_req": "aq_mouth_01+bd_tail_01",
        "archetype_tag": "Tempo_Speed",
        "card_art_asset_id": "art_sec_squall_ambush",
    },
    {
        "part_id": "sec_12",
        "part_type": "secret_combo",
        "class": "dawn",
        "part_name": "Hybrid Bird Aqua Secret Combo",
        "floop_id": "flp_sec_12",
        "floop_name": "Hydro Falcon",
        "activation_mana_cost": 2,
        "atk_bias_shift": 15,
        "def_bias_shift": -15,
        "effect_type": "DAMAGE",
        "base_value": 30,
        "scaling_formula": "BASE + (AXIE_MANA - 1) * 15",
        "conditional_rule": "NONE",
        "target_scope": "OPPOSING_LANE",
        "is_secret": 1,
        "secret_combo_req": "bd_mouth_01+aq_tail_01",
        "archetype_tag": "Evasive_Strike",
        "card_art_asset_id": "art_sec_hydro_falcon",
    },
]

# Standard 60 Parts Floop Configuration Template
STANDARD_PARTS_CONFIG = [
    # Beast Mouths (4)
    {"part_id": "b_mouth_01", "part_type": "mouth", "class": "beast", "part_name": "Nutcracker", "floop_id": "flp_b_mouth_01", "floop_name": "Nutcracker Bite", "activation_mana_cost": 1, "atk_bias_shift": 5, "def_bias_shift": -5, "effect_type": "DAMAGE", "base_value": 15, "scaling_formula": "BASE + (AXIE_MANA - 1) * 10", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_nutcracker"},
    {"part_id": "b_mouth_02", "part_type": "mouth", "class": "beast", "part_name": "Axie Kiss", "floop_id": "flp_b_mouth_02", "floop_name": "Death Kiss", "activation_mana_cost": 2, "atk_bias_shift": 10, "def_bias_shift": -10, "effect_type": "BUFF_ATK", "base_value": 12, "scaling_formula": "BASE + (AXIE_MANA - 1) * 8", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_axie_kiss"},
    {"part_id": "b_mouth_03", "part_type": "mouth", "class": "beast", "part_name": "Goda", "floop_id": "flp_b_mouth_03", "floop_name": "Piercing Howl", "activation_mana_cost": 1, "atk_bias_shift": 5, "def_bias_shift": -5, "effect_type": "DISCARD", "base_value": 10, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_goda"},
    {"part_id": "b_mouth_04", "part_type": "mouth", "class": "beast", "part_name": "Confident", "floop_id": "flp_b_mouth_04", "floop_name": "Self Assurance", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "BUFF_ATK", "base_value": 8, "scaling_formula": "BASE + (AXIE_MANA - 1) * 5", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_confident"},

    # Aqua Mouths (4)
    {"part_id": "aq_mouth_01", "part_type": "mouth", "class": "aqua", "part_name": "Lam", "floop_id": "flp_aq_mouth_01", "floop_name": "Angry Lam", "activation_mana_cost": 1, "atk_bias_shift": 5, "def_bias_shift": -5, "effect_type": "DAMAGE", "base_value": 14, "scaling_formula": "BASE + (AXIE_MANA - 1) * 8", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_lam"},
    {"part_id": "aq_mouth_02", "part_type": "mouth", "class": "aqua", "part_name": "Risky Fish", "floop_id": "flp_aq_mouth_02", "floop_name": "Fish Hook", "activation_mana_cost": 2, "atk_bias_shift": 10, "def_bias_shift": -10, "effect_type": "DAMAGE", "base_value": 22, "scaling_formula": "BASE + (AXIE_MANA - 1) * 12", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_risky_fish"},
    {"part_id": "aq_mouth_03", "part_type": "mouth", "class": "aqua", "part_name": "Piranha", "floop_id": "flp_aq_mouth_03", "floop_name": "Crimson Water", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "DAMAGE", "base_value": 10, "scaling_formula": "NONE", "conditional_rule": "TARGET_MANA <= AXIE_MANA", "target_scope": "OPPOSING_LANE", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_piranha"},
    {"part_id": "aq_mouth_04", "part_type": "mouth", "class": "aqua", "part_name": "Catfish", "floop_id": "flp_aq_mouth_04", "floop_name": "Swallow Whole", "activation_mana_cost": 2, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "HEAL", "base_value": 18, "scaling_formula": "BASE + (AXIE_MANA - 1) * 10", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_catfish"},

    # Plant Mouths (4)
    {"part_id": "pl_mouth_01", "part_type": "mouth", "class": "plant", "part_name": "Serious", "floop_id": "flp_pl_mouth_01", "floop_name": "Vegetal Bite", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "STEAL_MANA", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "TARGET_MANA <= AXIE_MANA", "target_scope": "OPPOSING_LANE", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_serious"},
    {"part_id": "pl_mouth_02", "part_type": "mouth", "class": "plant", "part_name": "Zigzag", "floop_id": "flp_pl_mouth_02", "floop_name": "Drain Bite", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "HEAL", "base_value": 12, "scaling_formula": "BASE + (AXIE_MANA - 1) * 6", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_zigzag"},
    {"part_id": "pl_mouth_03", "part_type": "mouth", "class": "plant", "part_name": "Herbivore", "floop_id": "flp_pl_mouth_03", "floop_name": "Vegan Diet", "activation_mana_cost": 2, "atk_bias_shift": -10, "def_bias_shift": 10, "effect_type": "SHIELD", "base_value": 25, "scaling_formula": "BASE + (AXIE_MANA - 1) * 15", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_herbivore"},
    {"part_id": "pl_mouth_04", "part_type": "mouth", "class": "plant", "part_name": "Silence Whisper", "floop_id": "flp_pl_mouth_04", "floop_name": "Forest Breath", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "HEAL", "base_value": 15, "scaling_formula": "BASE + (AXIE_MANA - 1) * 8", "conditional_rule": "NONE", "target_scope": "ALLIED_LANE", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_silence_whisper"},

    # Bird Mouths (4)
    {"part_id": "bd_mouth_01", "part_type": "mouth", "class": "bird", "part_name": "Doubletalk", "floop_id": "flp_bd_mouth_01", "floop_name": "Soothing Song", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "SLEEP", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_doubletalk"},
    {"part_id": "bd_mouth_02", "part_type": "mouth", "class": "bird", "part_name": "Peace Maker", "floop_id": "flp_bd_mouth_02", "floop_name": "Peace Treaty", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "DEBUFF_ATK", "base_value": 8, "scaling_formula": "BASE + (AXIE_MANA - 1) * 5", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_peace_maker"},
    {"part_id": "bd_mouth_03", "part_type": "mouth", "class": "bird", "part_name": "Little Owl", "floop_id": "flp_bd_mouth_03", "floop_name": "Dark Swoop", "activation_mana_cost": 2, "atk_bias_shift": 15, "def_bias_shift": -15, "effect_type": "BURST_DAMAGE", "base_value": 28, "scaling_formula": "BASE + (AXIE_MANA - 1) * 15", "conditional_rule": "NONE", "target_scope": "OPPOSING_HERO", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_little_owl"},
    {"part_id": "bd_mouth_04", "part_type": "mouth", "class": "bird", "part_name": "Hungry Bird", "floop_id": "flp_bd_mouth_04", "floop_name": "Insectivore", "activation_mana_cost": 1, "atk_bias_shift": 5, "def_bias_shift": -5, "effect_type": "DAMAGE", "base_value": 12, "scaling_formula": "BASE + (AXIE_MANA - 1) * 6", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_hungry_bird"},

    # Bug Mouths (4)
    {"part_id": "bg_mouth_01", "part_type": "mouth", "class": "bug", "part_name": "Mosquito", "floop_id": "flp_bg_mouth_01", "floop_name": "Blood Taste", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "HEAL", "base_value": 10, "scaling_formula": "BASE + (AXIE_MANA - 1) * 5", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_mosquito"},
    {"part_id": "bg_mouth_02", "part_type": "mouth", "class": "bug", "part_name": "Cute Bunny", "floop_id": "flp_bg_mouth_02", "floop_name": "Terror Chomp", "activation_mana_cost": 2, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "FEAR", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "TARGET_MANA <= AXIE_MANA", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_cute_bunny"},
    {"part_id": "bg_mouth_03", "part_type": "mouth", "class": "bug", "part_name": "Square Teeth", "floop_id": "flp_bg_mouth_03", "floop_name": "Nut Cracking", "activation_mana_cost": 1, "atk_bias_shift": 10, "def_bias_shift": -10, "effect_type": "DAMAGE", "base_value": 16, "scaling_formula": "BASE + (AXIE_MANA - 1) * 8", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_square_teeth"},
    {"part_id": "bg_mouth_04", "part_type": "mouth", "class": "bug", "part_name": "Pincer", "floop_id": "flp_bg_mouth_04", "floop_name": "Surgical Pincer", "activation_mana_cost": 1, "atk_bias_shift": 5, "def_bias_shift": -5, "effect_type": "DISCARD", "base_value": 12, "scaling_formula": "BASE + (AXIE_MANA - 1) * 6", "conditional_rule": "NONE", "target_scope": "ANY_LANE_ENEMY", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_pincer"},

    # Reptile Mouths (4)
    {"part_id": "rp_mouth_01", "part_type": "mouth", "class": "reptile", "part_name": "Toothless Bite", "floop_id": "flp_rp_mouth_01", "floop_name": "Sneaky Raid", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "DEBUFF_ATK", "base_value": 10, "scaling_formula": "BASE + (AXIE_MANA - 1) * 6", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_toothless_bite"},
    {"part_id": "rp_mouth_02", "part_type": "mouth", "class": "reptile", "part_name": "Kotaro", "floop_id": "flp_rp_mouth_02", "floop_name": "Kotaro Bite", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "GAIN_MANA", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "TARGET_MANA <= AXIE_MANA", "target_scope": "SELF", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_kotaro"},
    {"part_id": "rp_mouth_03", "part_type": "mouth", "class": "reptile", "part_name": "Razor Bite", "floop_id": "flp_rp_mouth_03", "floop_name": "Venom Fang", "activation_mana_cost": 2, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "POISON", "base_value": 2, "scaling_formula": "BASE + (AXIE_MANA - 1) * 1", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_razor_bite"},
    {"part_id": "rp_mouth_04", "part_type": "mouth", "class": "reptile", "part_name": "Tiny Turtle", "floop_id": "flp_rp_mouth_04", "floop_name": "Chomp", "activation_mana_cost": 2, "atk_bias_shift": -10, "def_bias_shift": 10, "effect_type": "STUN", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_tiny_turtle"},

    # Beast Tails (6)
    {"part_id": "b_tail_01", "part_type": "tail", "class": "beast", "part_name": "Cottontail", "floop_id": "flp_b_tail_01", "floop_name": "Luna Absorb", "activation_mana_cost": 0, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "GAIN_MANA", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_cottontail"},
    {"part_id": "b_tail_02", "part_type": "tail", "class": "beast", "part_name": "Rice", "floop_id": "flp_b_tail_02", "floop_name": "Night Rice", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "STEAL_MANA", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_rice"},
    {"part_id": "b_tail_03", "part_type": "tail", "class": "beast", "part_name": "Shiba", "floop_id": "flp_b_tail_03", "floop_name": "Shiba Strike", "activation_mana_cost": 2, "atk_bias_shift": 15, "def_bias_shift": -15, "effect_type": "DAMAGE", "base_value": 25, "scaling_formula": "BASE + (AXIE_MANA - 1) * 12", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_shiba"},
    {"part_id": "b_tail_04", "part_type": "tail", "class": "beast", "part_name": "Gerbil", "floop_id": "flp_b_tail_04", "floop_name": "Gerbil Jump", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "SWAP_LANE", "base_value": 0, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_gerbil"},
    {"part_id": "b_tail_05", "part_type": "tail", "class": "beast", "part_name": "Hare", "floop_id": "flp_b_tail_05", "floop_name": "Hare Rush", "activation_mana_cost": 1, "atk_bias_shift": 5, "def_bias_shift": -5, "effect_type": "DRAW", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_hare"},
    {"part_id": "b_tail_06", "part_type": "tail", "class": "beast", "part_name": "Nutcracker", "floop_id": "flp_b_tail_06", "floop_name": "Nutcracker Smack", "activation_mana_cost": 2, "atk_bias_shift": 10, "def_bias_shift": -10, "effect_type": "DAMAGE", "base_value": 20, "scaling_formula": "BASE + (AXIE_MANA - 1) * 10", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Corn_Aggro", "card_art_asset_id": "art_flp_nutcracker_tail"},

    # Aqua Tails (6)
    {"part_id": "aq_tail_01", "part_type": "tail", "class": "aqua", "part_name": "Koi", "floop_id": "flp_aq_tail_01", "floop_name": "Upstream Swift", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "BUFF_SPEED", "base_value": 10, "scaling_formula": "BASE + (AXIE_MANA - 1) * 5", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_koi"},
    {"part_id": "aq_tail_02", "part_type": "tail", "class": "aqua", "part_name": "Nimo", "floop_id": "flp_aq_tail_02", "floop_name": "Tail Slap", "activation_mana_cost": 0, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "GAIN_MANA", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_nimo"},
    {"part_id": "aq_tail_03", "part_type": "tail", "class": "aqua", "part_name": "Tadpole", "floop_id": "flp_aq_tail_03", "floop_name": "Black Bubble", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "DEBUFF_ATK", "base_value": 6, "scaling_formula": "BASE + (AXIE_MANA - 1) * 4", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_tadpole"},
    {"part_id": "aq_tail_04", "part_type": "tail", "class": "aqua", "part_name": "Ranchu", "floop_id": "flp_aq_tail_04", "floop_name": "Water Spout", "activation_mana_cost": 2, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "DEBUFF_ATK", "base_value": 15, "scaling_formula": "BASE + (AXIE_MANA - 1) * 8", "conditional_rule": "NONE", "target_scope": "ANY_LANE_ENEMY", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_ranchu"},
    {"part_id": "aq_tail_05", "part_type": "tail", "class": "aqua", "part_name": "Navaga", "floop_id": "flp_aq_tail_05", "floop_name": "Ice Spear", "activation_mana_cost": 1, "atk_bias_shift": 5, "def_bias_shift": -5, "effect_type": "DAMAGE", "base_value": 12, "scaling_formula": "BASE + (AXIE_MANA - 1) * 6", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_navaga"},
    {"part_id": "aq_tail_06", "part_type": "tail", "class": "aqua", "part_name": "Shrimp", "floop_id": "flp_aq_tail_06", "floop_name": "Chitin Jump", "activation_mana_cost": 2, "atk_bias_shift": 10, "def_bias_shift": -10, "effect_type": "BURST_DAMAGE", "base_value": 24, "scaling_formula": "BASE + (AXIE_MANA - 1) * 12", "conditional_rule": "NONE", "target_scope": "OPPOSING_HERO", "archetype_tag": "Blue_Tempo", "card_art_asset_id": "art_flp_shrimp"},

    # Plant Tails (6)
    {"part_id": "pl_tail_01", "part_type": "tail", "class": "plant", "part_name": "Carrot", "floop_id": "flp_pl_tail_01", "floop_name": "Carrot Hammer", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "SHIELD", "base_value": 20, "scaling_formula": "BASE + (AXIE_MANA - 1) * 10", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_carrot"},
    {"part_id": "pl_tail_02", "part_type": "tail", "class": "plant", "part_name": "Cattail", "floop_id": "flp_pl_tail_02", "floop_name": "Cattail Slap", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "DRAW", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "TARGET_MANA <= AXIE_MANA", "target_scope": "SELF", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_cattail"},
    {"part_id": "pl_tail_03", "part_type": "tail", "class": "plant", "part_name": "Hatsune", "floop_id": "flp_pl_tail_03", "floop_name": "Forest Glow", "activation_mana_cost": 2, "atk_bias_shift": -10, "def_bias_shift": 10, "effect_type": "SHIELD", "base_value": 28, "scaling_formula": "BASE + (AXIE_MANA - 1) * 14", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_hatsune"},
    {"part_id": "pl_tail_04", "part_type": "tail", "class": "plant", "part_name": "Yam", "floop_id": "flp_pl_tail_04", "floop_name": "Gas Unleash", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "POISON", "base_value": 2, "scaling_formula": "BASE + (AXIE_MANA - 1) * 1", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_yam"},
    {"part_id": "pl_tail_05", "part_type": "tail", "class": "plant", "part_name": "Potato Leaf", "floop_id": "flp_pl_tail_05", "floop_name": "Aqua Defense", "activation_mana_cost": 1, "atk_bias_shift": -10, "def_bias_shift": 10, "effect_type": "SHIELD", "base_value": 22, "scaling_formula": "BASE + (AXIE_MANA - 1) * 10", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_potato_leaf"},
    {"part_id": "pl_tail_06", "part_type": "tail", "class": "plant", "part_name": "Hot Butt", "floop_id": "flp_pl_tail_06", "floop_name": "Spicy Surprise", "activation_mana_cost": 2, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "DAMAGE", "base_value": 18, "scaling_formula": "BASE + (AXIE_MANA - 1) * 8", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Nice_Sustain", "card_art_asset_id": "art_flp_hot_butt"},

    # Bird Tails (6)
    {"part_id": "bd_tail_01", "part_type": "tail", "class": "bird", "part_name": "Swallow", "floop_id": "flp_bd_tail_01", "floop_name": "Early Storm", "activation_mana_cost": 1, "atk_bias_shift": 5, "def_bias_shift": -5, "effect_type": "DAMAGE", "base_value": 14, "scaling_formula": "BASE + (AXIE_MANA - 1) * 7", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_swallow"},
    {"part_id": "bd_tail_02", "part_type": "tail", "class": "bird", "part_name": "Feather Fan", "floop_id": "flp_bd_tail_02", "floop_name": "Triple Feather", "activation_mana_cost": 2, "atk_bias_shift": 10, "def_bias_shift": -10, "effect_type": "DAMAGE", "base_value": 26, "scaling_formula": "BASE + (AXIE_MANA - 1) * 14", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_feather_fan"},
    {"part_id": "bd_tail_03", "part_type": "tail", "class": "bird", "part_name": "The Last One", "floop_id": "flp_bd_tail_03", "floop_name": "Risky Feather", "activation_mana_cost": 2, "atk_bias_shift": 15, "def_bias_shift": -15, "effect_type": "BURST_DAMAGE", "base_value": 30, "scaling_formula": "BASE + (AXIE_MANA - 1) * 15", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_the_last_one"},
    {"part_id": "bd_tail_04", "part_type": "tail", "class": "bird", "part_name": "Cloud", "floop_id": "flp_bd_tail_04", "floop_name": "Puffy Feather", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "SWAP_LANE", "base_value": 0, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_cloud"},
    {"part_id": "bd_tail_05", "part_type": "tail", "class": "bird", "part_name": "Granma's Fan", "floop_id": "flp_bd_tail_05", "floop_name": "Cool Breeze", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "DEBUFF_ATK", "base_value": 8, "scaling_formula": "BASE + (AXIE_MANA - 1) * 4", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_granmas_fan"},
    {"part_id": "bd_tail_06", "part_type": "tail", "class": "bird", "part_name": "Post Fight", "floop_id": "flp_bd_tail_06", "floop_name": "All-out Shot", "activation_mana_cost": 2, "atk_bias_shift": 20, "def_bias_shift": -20, "effect_type": "BURST_DAMAGE", "base_value": 35, "scaling_formula": "BASE + (AXIE_MANA - 1) * 18", "conditional_rule": "NONE", "target_scope": "OPPOSING_HERO", "archetype_tag": "Swamp_Backdoor", "card_art_asset_id": "art_flp_post_fight"},

    # Bug Tails (6)
    {"part_id": "bg_tail_01", "part_type": "tail", "class": "bug", "part_name": "Ant", "floop_id": "flp_bg_tail_01", "floop_name": "Chemical Warfare", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "DISCARD", "base_value": 8, "scaling_formula": "BASE + (AXIE_MANA - 1) * 4", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_ant"},
    {"part_id": "bg_tail_02", "part_type": "tail", "class": "bug", "part_name": "Twin Needle", "floop_id": "flp_bg_tail_02", "floop_name": "Double Stab", "activation_mana_cost": 2, "atk_bias_shift": 10, "def_bias_shift": -10, "effect_type": "DAMAGE", "base_value": 24, "scaling_formula": "BASE + (AXIE_MANA - 1) * 12", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_twin_needle"},
    {"part_id": "bg_tail_03", "part_type": "tail", "class": "bug", "part_name": "Fish Snack", "floop_id": "flp_bg_tail_03", "floop_name": "Anesthetic Bait", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "STUN", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "TARGET_MANA <= AXIE_MANA", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_fish_snack"},
    {"part_id": "bg_tail_04", "part_type": "tail", "class": "bug", "part_name": "Gravel Ant", "floop_id": "flp_bg_tail_04", "floop_name": "Sand Trap", "activation_mana_cost": 2, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "DISABLE_FLOP", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_gravel_ant"},
    {"part_id": "bg_tail_05", "part_type": "tail", "class": "bug", "part_name": "Pupae", "floop_id": "flp_bg_tail_05", "floop_name": "Metamorphosis", "activation_mana_cost": 1, "atk_bias_shift": -10, "def_bias_shift": 10, "effect_type": "SHIELD", "base_value": 20, "scaling_formula": "BASE + (AXIE_MANA - 1) * 10", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_pupae"},
    {"part_id": "bg_tail_06", "part_type": "tail", "class": "bug", "part_name": "Thorny Caterpillar", "floop_id": "flp_bg_tail_06", "floop_name": "Allergic React", "activation_mana_cost": 2, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "DAMAGE", "base_value": 22, "scaling_formula": "BASE + (AXIE_MANA - 1) * 10", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Swamp_Disruption", "card_art_asset_id": "art_flp_thorny_caterpillar"},

    # Reptile Tails (6)
    {"part_id": "rp_tail_01", "part_type": "tail", "class": "reptile", "part_name": "Wall Gecko", "floop_id": "flp_rp_tail_01", "floop_name": "Critical Escape", "activation_mana_cost": 1, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "SHIELD", "base_value": 18, "scaling_formula": "BASE + (AXIE_MANA - 1) * 8", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_wall_gecko"},
    {"part_id": "rp_tail_02", "part_type": "tail", "class": "reptile", "part_name": "Iguana", "floop_id": "flp_rp_tail_02", "floop_name": "Scale Dart", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "STEAL_MANA", "base_value": 1, "scaling_formula": "NONE", "conditional_rule": "TARGET_MANA <= AXIE_MANA", "target_scope": "OPPOSING_LANE", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_iguana"},
    {"part_id": "rp_tail_03", "part_type": "tail", "class": "reptile", "part_name": "Tiny Dino", "floop_id": "flp_rp_tail_03", "floop_name": "Tiny Stomp", "activation_mana_cost": 2, "atk_bias_shift": 5, "def_bias_shift": -5, "effect_type": "DAMAGE", "base_value": 20, "scaling_formula": "BASE + (AXIE_MANA - 1) * 10", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_tiny_dino"},
    {"part_id": "rp_tail_04", "part_type": "tail", "class": "reptile", "part_name": "Snake Jar", "floop_id": "flp_rp_tail_04", "floop_name": "Jar Armor", "activation_mana_cost": 2, "atk_bias_shift": -10, "def_bias_shift": 10, "effect_type": "SHIELD", "base_value": 26, "scaling_formula": "BASE + (AXIE_MANA - 1) * 12", "conditional_rule": "NONE", "target_scope": "SELF", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_snake_jar"},
    {"part_id": "rp_tail_05", "part_type": "tail", "class": "reptile", "part_name": "Gila", "floop_id": "flp_rp_tail_05", "floop_name": "Neurotoxin", "activation_mana_cost": 2, "atk_bias_shift": -5, "def_bias_shift": 5, "effect_type": "POISON", "base_value": 3, "scaling_formula": "BASE + (AXIE_MANA - 1) * 1", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_gila"},
    {"part_id": "rp_tail_06", "part_type": "tail", "class": "reptile", "part_name": "Grass Snake", "floop_id": "flp_rp_tail_06", "floop_name": "Venom Spray", "activation_mana_cost": 1, "atk_bias_shift": 0, "def_bias_shift": 0, "effect_type": "POISON", "base_value": 2, "scaling_formula": "NONE", "conditional_rule": "NONE", "target_scope": "OPPOSING_LANE", "archetype_tag": "Sandy_Attrition", "card_art_asset_id": "art_flp_grass_snake"},
]


def compile_floops_matrix():
    """Generates axie_part_floops_matrix.csv (72 data rows + 1 header = 73 lines)."""
    rows = []
    
    # 1. 60 Standard parts
    for part in STANDARD_PARTS_CONFIG:
        # Stat conservation assertion
        assert part["atk_bias_shift"] + part["def_bias_shift"] == 0, f"Stat conservation violated for {part['part_id']}"
        rows.append({
            "part_id": part["part_id"],
            "part_type": part["part_type"],
            "class": part["class"],
            "part_name": part["part_name"],
            "floop_id": part["floop_id"],
            "floop_name": part["floop_name"],
            "activation_mana_cost": part["activation_mana_cost"],
            "atk_bias_shift": part["atk_bias_shift"],
            "def_bias_shift": part["def_bias_shift"],
            "effect_type": part["effect_type"],
            "base_value": part["base_value"],
            "scaling_formula": part["scaling_formula"],
            "conditional_rule": part["conditional_rule"],
            "target_scope": part["target_scope"],
            "is_secret": 0,
            "secret_combo_req": "NONE",
            "archetype_tag": part["archetype_tag"],
            "card_art_asset_id": part["card_art_asset_id"]
        })

    # Collect valid standard part IDs for foreign key validation
    valid_part_ids = {r["part_id"] for r in rows}

    # 2. 12 Secret Combos
    for sec in SECRET_COMBOS:
        assert sec["atk_bias_shift"] + sec["def_bias_shift"] == 0, f"Stat conservation violated for {sec['part_id']}"
        # Validate foreign keys
        mouth_req, tail_req = sec["secret_combo_req"].split("+")
        assert mouth_req in valid_part_ids, f"Dangling foreign key mouth {mouth_req} in {sec['part_id']}"
        assert tail_req in valid_part_ids, f"Dangling foreign key tail {tail_req} in {sec['part_id']}"
        rows.append(sec)

    assert len(rows) == 72, f"Expected exactly 72 rows, got {len(rows)}"

    fieldnames = [
        "part_id", "part_type", "class", "part_name", "floop_id", "floop_name",
        "activation_mana_cost", "atk_bias_shift", "def_bias_shift", "effect_type",
        "base_value", "scaling_formula", "conditional_rule", "target_scope",
        "is_secret", "secret_combo_req", "archetype_tag", "card_art_asset_id"
    ]

    with open(OUTPUT_FLOOPS_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"✓ Generated {OUTPUT_FLOOPS_PATH} ({len(rows) + 1} lines)")


def compile_structures_master():
    """Generates structures_master.csv (30 data rows + 1 header = 31 lines)."""
    structures = [
        {"structure_id": "str_01", "name": "Astral Citadel", "axie_class_affinity": "neutral", "mana_cost": 3, "base_hp": 20, "armor_reduction": 2, "passive_effect_type": "BUFF_DEF", "effect_value": 4, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +4 Defense.", "card_art_asset_id": "asset_struct_astral_citadel"},
        {"structure_id": "str_02", "name": "Spike Spire", "axie_class_affinity": "bug", "mana_cost": 3, "base_hp": 15, "armor_reduction": 1, "passive_effect_type": "DAMAGE_TRIGGER", "effect_value": 5, "scaling_formula": "NONE", "activation_trigger": "ON_DESTROY", "target_scope": "HERO", "lore_description": "Deals 5 damage to opposing hero when a creature in this lane is destroyed.", "card_art_asset_id": "asset_struct_spike_spire"},
        {"structure_id": "str_03", "name": "Verdant Greenhouse", "axie_class_affinity": "plant", "mana_cost": 2, "base_hp": 18, "armor_reduction": 1, "passive_effect_type": "SWAP_STATS", "effect_value": 0, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creatures in this lane swap Attack and Defense.", "card_art_asset_id": "asset_struct_verdant_greenhouse"},
        {"structure_id": "str_04", "name": "Coral Sanctuary", "axie_class_affinity": "aquatic", "mana_cost": 1, "base_hp": 12, "armor_reduction": 0, "passive_effect_type": "BUFF_DEF", "effect_value": 4, "scaling_formula": "SCALING_COUNT", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +2 Defense for each allied unit on field.", "card_art_asset_id": "asset_struct_coral_sanctuary"},
        {"structure_id": "str_05", "name": "Abyssal Grotto", "axie_class_affinity": "aquatic", "mana_cost": 2, "base_hp": 15, "armor_reduction": 1, "passive_effect_type": "BUFF_DEF", "effect_value": 5, "scaling_formula": "SCALING_COUNT", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +5 Attack and +5 Defense for each empty lane.", "card_art_asset_id": "asset_struct_abyssal_grotto"},
        {"structure_id": "str_06", "name": "Tidal Spring", "axie_class_affinity": "aquatic", "mana_cost": 2, "base_hp": 16, "armor_reduction": 1, "passive_effect_type": "HEAL_TRIGGER", "effect_value": 2, "scaling_formula": "SCALING_COUNT", "activation_trigger": "START_OF_TURN", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane heals 2 HP for each allied unit at start of turn.", "card_art_asset_id": "asset_struct_tidal_spring"},
        {"structure_id": "str_07", "name": "Beast Den Stronghold", "axie_class_affinity": "beast", "mana_cost": 3, "base_hp": 20, "armor_reduction": 2, "passive_effect_type": "BUFF_ATK", "effect_value": 2, "scaling_formula": "SCALING_COUNT", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +2 Attack for each allied unit on field.", "card_art_asset_id": "asset_struct_beast_den_stronghold"},
        {"structure_id": "str_08", "name": "Primal Arena", "axie_class_affinity": "beast", "mana_cost": 2, "base_hp": 12, "armor_reduction": 0, "passive_effect_type": "BUFF_ATK", "effect_value": 3, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +3 Attack.", "card_art_asset_id": "asset_struct_primal_arena"},
        {"structure_id": "str_09", "name": "Atia Parthenon", "axie_class_affinity": "beast", "mana_cost": 4, "base_hp": 25, "armor_reduction": 3, "passive_effect_type": "BUFF_ATK", "effect_value": 2, "scaling_formula": "SCALING_COUNT", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +2 Attack for each different affinity on field.", "card_art_asset_id": "asset_struct_atia_parthenon"},
        {"structure_id": "str_10", "name": "Forest Shrine", "axie_class_affinity": "plant", "mana_cost": 3, "base_hp": 24, "armor_reduction": 2, "passive_effect_type": "BUFF_DEF", "effect_value": 9, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +9 Defense.", "card_art_asset_id": "asset_struct_forest_shrine"},
        {"structure_id": "str_11", "name": "Bone Reliquary", "axie_class_affinity": "reptile", "mana_cost": 1, "base_hp": 10, "armor_reduction": 0, "passive_effect_type": "UTILITY", "effect_value": 1, "scaling_formula": "NONE", "activation_trigger": "ON_DESTROY", "target_scope": "LANE_UNIT", "lore_description": "When creature in this lane is destroyed return it to hand and discard structure.", "card_art_asset_id": "asset_struct_bone_reliquary"},
        {"structure_id": "str_12", "name": "Haunted Eyrie", "axie_class_affinity": "bird", "mana_cost": 4, "base_hp": 22, "armor_reduction": 2, "passive_effect_type": "BUFF_DEF", "effect_value": 8, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +8 Attack and +8 Defense.", "card_art_asset_id": "asset_struct_haunted_eyrie"},
        {"structure_id": "str_13", "name": "Lunacian Watermill", "axie_class_affinity": "aquatic", "mana_cost": 2, "base_hp": 15, "armor_reduction": 1, "passive_effect_type": "UTILITY", "effect_value": 1, "scaling_formula": "NONE", "activation_trigger": "ON_FLOOP", "target_scope": "LANE_UNIT", "lore_description": "Gain 1 Energy when creature in this lane activates an ability.", "card_art_asset_id": "asset_struct_lunacian_watermill"},
        {"structure_id": "str_14", "name": "Reptilian Crypt", "axie_class_affinity": "reptile", "mana_cost": 2, "base_hp": 14, "armor_reduction": 1, "passive_effect_type": "UTILITY", "effect_value": 1, "scaling_formula": "NONE", "activation_trigger": "ON_DESTROY", "target_scope": "LANE_UNIT", "lore_description": "When creature in this lane is destroyed return it to hand and discard structure.", "card_art_asset_id": "asset_struct_reptilian_crypt"},
        {"structure_id": "str_15", "name": "Yggdrasil Tower", "axie_class_affinity": "plant", "mana_cost": 3, "base_hp": 20, "armor_reduction": 2, "passive_effect_type": "HEAL_TRIGGER", "effect_value": 5, "scaling_formula": "NONE", "activation_trigger": "START_OF_TURN", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane heals 5 HP at start of turn.", "card_art_asset_id": "asset_struct_yggdrasil_tower"},
        {"structure_id": "str_16", "name": "Sunken Obelisk", "axie_class_affinity": "bug", "mana_cost": 2, "base_hp": 16, "armor_reduction": 1, "passive_effect_type": "DAMAGE_TRIGGER", "effect_value": 4, "scaling_formula": "NONE", "activation_trigger": "ON_DESTROY", "target_scope": "HERO", "lore_description": "Deal 4 damage to opposing hero when allied creature in this lane is destroyed.", "card_art_asset_id": "asset_struct_sunken_obelisk"},
        {"structure_id": "str_17", "name": "Chitin Palace", "axie_class_affinity": "reptile", "mana_cost": 2, "base_hp": 14, "armor_reduction": 1, "passive_effect_type": "DAMAGE_TRIGGER", "effect_value": 5, "scaling_formula": "NONE", "activation_trigger": "ON_SUMMON", "target_scope": "LANE_UNIT", "lore_description": "Deal 5 damage to opposing creature when a new unit is deployed in this lane.", "card_art_asset_id": "asset_struct_chitin_palace"},
        {"structure_id": "str_18", "name": "Lunalog Bastion", "axie_class_affinity": "plant", "mana_cost": 3, "base_hp": 20, "armor_reduction": 2, "passive_effect_type": "HEAL_TRIGGER", "effect_value": 5, "scaling_formula": "NONE", "activation_trigger": "ON_DESTROY", "target_scope": "HERO", "lore_description": "Heal 5 HP to your hero when a creature in this lane is destroyed.", "card_art_asset_id": "asset_struct_lunalog_bastion"},
        {"structure_id": "str_19", "name": "Savannah Pyramidia", "axie_class_affinity": "reptile", "mana_cost": 2, "base_hp": 18, "armor_reduction": 1, "passive_effect_type": "BUFF_DEF", "effect_value": 2, "scaling_formula": "SCALING_COUNT", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +2 Defense for each card in your hand.", "card_art_asset_id": "asset_struct_savannah_pyramidia"},
        {"structure_id": "str_20", "name": "Desert Bastion", "axie_class_affinity": "reptile", "mana_cost": 2, "base_hp": 16, "armor_reduction": 1, "passive_effect_type": "BUFF_DEF", "effect_value": 4, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +4 Attack and +4 Defense.", "card_art_asset_id": "asset_struct_desert_bastion"},
        {"structure_id": "str_21", "name": "Golden Monument", "axie_class_affinity": "reptile", "mana_cost": 2, "base_hp": 15, "armor_reduction": 1, "passive_effect_type": "HEAL_TRIGGER", "effect_value": 5, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane heals 5 HP when it destroys an opposing unit.", "card_art_asset_id": "asset_struct_golden_monument"},
        {"structure_id": "str_22", "name": "Solar Spire", "axie_class_affinity": "bird", "mana_cost": 4, "base_hp": 25, "armor_reduction": 3, "passive_effect_type": "BUFF_DEF", "effect_value": 5, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane takes 5 less damage when attacked.", "card_art_asset_id": "asset_struct_solar_spire"},
        {"structure_id": "str_23", "name": "Academy of Botanics", "axie_class_affinity": "plant", "mana_cost": 2, "base_hp": 18, "armor_reduction": 1, "passive_effect_type": "BUFF_DEF", "effect_value": 5, "scaling_formula": "NONE", "activation_trigger": "ON_FLOOP", "target_scope": "LANE_UNIT", "lore_description": "Allied creature in this lane gets +5 Defense when it activates an ability.", "card_art_asset_id": "asset_struct_academy_of_botanics"},
        {"structure_id": "str_24", "name": "Void Sanctum", "axie_class_affinity": "neutral", "mana_cost": 4, "base_hp": 22, "armor_reduction": 2, "passive_effect_type": "UTILITY", "effect_value": 1, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Enemy may only deploy creatures of Rarity 3 or lower into this lane.", "card_art_asset_id": "asset_struct_void_sanctum"},
        {"structure_id": "str_25", "name": "Outpost of Vigor", "axie_class_affinity": "beast", "mana_cost": 2, "base_hp": 15, "armor_reduction": 1, "passive_effect_type": "BUFF_ATK", "effect_value": 2, "scaling_formula": "SCALING_COUNT", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +2 Attack for each card in opponent hand.", "card_art_asset_id": "asset_struct_outpost_of_vigor"},
        {"structure_id": "str_26", "name": "Crimson Barricade", "axie_class_affinity": "bug", "mana_cost": 2, "base_hp": 16, "armor_reduction": 1, "passive_effect_type": "DAMAGE_TRIGGER", "effect_value": 5, "scaling_formula": "NONE", "activation_trigger": "ON_SUMMON", "target_scope": "HERO", "lore_description": "Deal 5 damage to opposing hero when a new unit is deployed in this lane.", "card_art_asset_id": "asset_struct_crimson_barricade"},
        {"structure_id": "str_27", "name": "Mystic Megalith", "axie_class_affinity": "aquatic", "mana_cost": 4, "base_hp": 20, "armor_reduction": 2, "passive_effect_type": "UTILITY", "effect_value": 1, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Abilities cost 1 less Energy for creature in this lane.", "card_art_asset_id": "asset_struct_mystic_megalith"},
        {"structure_id": "str_28", "name": "Solar Beacon", "axie_class_affinity": "bird", "mana_cost": 2, "base_hp": 18, "armor_reduction": 1, "passive_effect_type": "BUFF_ATK", "effect_value": 4, "scaling_formula": "NONE", "activation_trigger": "ON_FLOOP", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +4 Attack every time it activates an ability.", "card_art_asset_id": "asset_struct_solar_beacon"},
        {"structure_id": "str_29", "name": "Bramble Keep", "axie_class_affinity": "beast", "mana_cost": 2, "base_hp": 16, "armor_reduction": 1, "passive_effect_type": "BUFF_DEF", "effect_value": 4, "scaling_formula": "NONE", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +4 Attack and +4 Defense.", "card_art_asset_id": "asset_struct_bramble_keep"},
        {"structure_id": "str_30", "name": "Nomad Camp", "axie_class_affinity": "neutral", "mana_cost": 1, "base_hp": 14, "armor_reduction": 1, "passive_effect_type": "BUFF_DEF", "effect_value": 3, "scaling_formula": "SCALING_COUNT", "activation_trigger": "PASSIVE", "target_scope": "LANE_UNIT", "lore_description": "Creature in this lane gets +3 Defense for each allied unit on field.", "card_art_asset_id": "asset_struct_nomad_camp"},
    ]

    assert len(structures) == 30, f"Expected 30 structures, found {len(structures)}"
    assert sum(s["mana_cost"] for s in structures) == 73, f"Sum of mana costs must be 73, got {sum(s['mana_cost'] for s in structures)}"

    fieldnames = [
        "structure_id", "name", "axie_class_affinity", "mana_cost", "base_hp",
        "armor_reduction", "passive_effect_type", "effect_value", "scaling_formula",
        "activation_trigger", "target_scope", "lore_description", "card_art_asset_id"
    ]

    with open(OUTPUT_STRUCTURES_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(structures)

    print(f"✓ Generated {OUTPUT_STRUCTURES_PATH} ({len(structures) + 1} lines)")


def compile_spells_master():
    """Generates spells_master.csv (49 data rows + 1 header = 50 lines)."""
    spells = [
        {"spell_id": "spl_01", "name": "Tidal Surge", "axie_class_affinity": "aquatic", "mana_cost": 4, "spell_type": "GLOBAL", "effect_type": "DESTROY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "ALL_CREATURES", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Destroy one allied creature and one opposing creature. Draw 1 card.", "card_art_asset_id": "asset_spell_tidal_surge"},
        {"spell_id": "spl_02", "name": "Pure Water", "axie_class_affinity": "aquatic", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "DESTROY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Sacrifice an allied creature to draw 1 card.", "card_art_asset_id": "asset_spell_pure_water"},
        {"spell_id": "spl_03", "name": "Black Void Pendant", "axie_class_affinity": "neutral", "mana_cost": 3, "spell_type": "GLOBAL", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "ALL_CREATURES", "cast_window": "ACTION_PHASE", "rarity": "EPIC", "description": "Reduce Defense of all creatures by 50%.", "card_art_asset_id": "asset_spell_black_void_pendant"},
        {"spell_id": "spl_04", "name": "Bloodlust Transfusion", "axie_class_affinity": "beast", "mana_cost": 2, "spell_type": "TARGETED", "effect_type": "DAMAGE", "base_value": 5, "scaling_formula": "NONE", "target_scope": "HERO", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Deal 5 damage to opposing hero and restore 5 HP to your hero.", "card_art_asset_id": "asset_spell_bloodlust_transfusion"},
        {"spell_id": "spl_05", "name": "Venomous Scepter", "axie_class_affinity": "reptile", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose a Reptile ally to strike opposing lane unit immediately.", "card_art_asset_id": "asset_spell_venomous_scepter"},
        {"spell_id": "spl_06", "name": "Atias Quickening", "axie_class_affinity": "neutral", "mana_cost": 1, "spell_type": "INSTANT", "effect_type": "MANA_SURGE", "base_value": 2, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Every card played this round costs 1 less Energy.", "card_art_asset_id": "asset_spell_atias_quickening"},
        {"spell_id": "spl_07", "name": "Yggdrasil Blessing", "axie_class_affinity": "plant", "mana_cost": 2, "spell_type": "INSTANT", "effect_type": "DRAW", "base_value": 3, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Draw 3 cards from your deck.", "card_art_asset_id": "asset_spell_yggdrasil_blessing"},
        {"spell_id": "spl_08", "name": "Cerebral Bloodstorm", "axie_class_affinity": "neutral", "mana_cost": 4, "spell_type": "TARGETED", "effect_type": "DAMAGE", "base_value": 5, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "EPIC", "description": "Choose an opposing unit and deal damage equal to its own Attack.", "card_art_asset_id": "asset_spell_cerebral_bloodstorm"},
        {"spell_id": "spl_09", "name": "Clairvoyant Daggerstorm", "axie_class_affinity": "neutral", "mana_cost": 2, "spell_type": "TARGETED", "effect_type": "DAMAGE", "base_value": 5, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Choose an enemy unit and double the damage taken on it.", "card_art_asset_id": "asset_spell_clairvoyant_daggerstorm"},
        {"spell_id": "spl_10", "name": "Primal Scepter", "axie_class_affinity": "beast", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose a Beast ally to strike opposing lane unit immediately.", "card_art_asset_id": "asset_spell_primal_scepter"},
        {"spell_id": "spl_11", "name": "Nectar Swap", "axie_class_affinity": "bug", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "SWAP_STATS", "base_value": 0, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose an allied unit and swap its Attack and Defense values.", "card_art_asset_id": "asset_spell_nectar_swap"},
        {"spell_id": "spl_12", "name": "Lunacian Scrying Orb", "axie_class_affinity": "neutral", "mana_cost": 2, "spell_type": "INSTANT", "effect_type": "DRAW", "base_value": 5, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Shuffle your hand into deck and draw 5 new cards.", "card_art_asset_id": "asset_spell_lunacian_scrying_orb"},
        {"spell_id": "spl_13", "name": "Shadow Gate", "axie_class_affinity": "neutral", "mana_cost": 2, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "LANE", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Choose an opposing structure and move it to an empty lane.", "card_art_asset_id": "asset_spell_shadow_gate"},
        {"spell_id": "spl_14", "name": "Barrier of Sanctuary", "axie_class_affinity": "plant", "mana_cost": 4, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "EPIC", "description": "Opponent cannot summon creatures next round.", "card_art_asset_id": "asset_spell_barrier_of_sanctuary"},
        {"spell_id": "spl_15", "name": "Falling Astral Star", "axie_class_affinity": "neutral", "mana_cost": 2, "spell_type": "INSTANT", "effect_type": "MANA_SURGE", "base_value": 2, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Opponent gets 2 less Energy next round.", "card_art_asset_id": "asset_spell_falling_astral_star"},
        {"spell_id": "spl_16", "name": "Terror Nightmare Field", "axie_class_affinity": "bug", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose an opposing creature. It cannot use abilities next round.", "card_art_asset_id": "asset_spell_terror_nightmare_field"},
        {"spell_id": "spl_17", "name": "Fountain of Vitality", "axie_class_affinity": "aquatic", "mana_cost": 2, "spell_type": "TARGETED", "effect_type": "HEAL", "base_value": 5, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose a damaged allied creature and heal it equal to its Attack.", "card_art_asset_id": "asset_spell_fountain_of_vitality"},
        {"spell_id": "spl_18", "name": "Chitin Sacrifice", "axie_class_affinity": "bug", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "DESTROY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Destroy one of your structures and draw 1 card.", "card_art_asset_id": "asset_spell_chitin_sacrifice"},
        {"spell_id": "spl_19", "name": "Seismic Tremor", "axie_class_affinity": "neutral", "mana_cost": 2, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Opponent cannot summon structures next round.", "card_art_asset_id": "asset_spell_seismic_tremor"},
        {"spell_id": "spl_20", "name": "Mystic Chimera Egg", "axie_class_affinity": "neutral", "mana_cost": 2, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Put a random creature from your deck into your hand.", "card_art_asset_id": "asset_spell_mystic_chimera_egg"},
        {"spell_id": "spl_21", "name": "Radiant Purge", "axie_class_affinity": "bird", "mana_cost": 3, "spell_type": "GLOBAL", "effect_type": "DESTROY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "ALL_CREATURES", "cast_window": "ACTION_PHASE", "rarity": "EPIC", "description": "Destroy all enemy creatures of Rarity 4 or higher.", "card_art_asset_id": "asset_spell_radiant_purge"},
        {"spell_id": "spl_22", "name": "Solitary Reaping", "axie_class_affinity": "neutral", "mana_cost": 2, "spell_type": "GLOBAL", "effect_type": "DESTROY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "ALL_CREATURES", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Destroys the lone creature on opponent side of field.", "card_art_asset_id": "asset_spell_solitary_reaping"},
        {"spell_id": "spl_23", "name": "Feathered Strike", "axie_class_affinity": "bird", "mana_cost": 4, "spell_type": "TARGETED", "effect_type": "DAMAGE", "base_value": 10, "scaling_formula": "NONE", "target_scope": "HERO", "cast_window": "ACTION_PHASE", "rarity": "EPIC", "description": "Deal 10 damage to opposing hero and restore 10 HP to your hero.", "card_art_asset_id": "asset_spell_feathered_strike"},
        {"spell_id": "spl_24", "name": "Mending Rain", "axie_class_affinity": "aquatic", "mana_cost": 3, "spell_type": "GLOBAL", "effect_type": "HEAL", "base_value": 5, "scaling_formula": "NONE", "target_scope": "ALL_CREATURES", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Heal all creatures on the field by 5 HP.", "card_art_asset_id": "asset_spell_mending_rain"},
        {"spell_id": "spl_25", "name": "Recall Portal", "axie_class_affinity": "neutral", "mana_cost": 3, "spell_type": "GLOBAL", "effect_type": "RETURN_HAND", "base_value": 1, "scaling_formula": "NONE", "target_scope": "ALL_CREATURES", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Return all of your creatures on the field to your hand.", "card_art_asset_id": "asset_spell_recall_portal"},
        {"spell_id": "spl_26", "name": "Arcane Silence", "axie_class_affinity": "neutral", "mana_cost": 3, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "EPIC", "description": "Opponent cannot cast spells next round.", "card_art_asset_id": "asset_spell_arcane_silence"},
        {"spell_id": "spl_27", "name": "Aquatic Wave Claws", "axie_class_affinity": "aquatic", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose an Aquatic creature and attack opposing creature in its lane.", "card_art_asset_id": "asset_spell_aquatic_wave_claws"},
        {"spell_id": "spl_28", "name": "Scroll of Arcane Reclamation", "axie_class_affinity": "neutral", "mana_cost": 2, "spell_type": "INSTANT", "effect_type": "RETURN_HAND", "base_value": 1, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Return a Spell card from discard pile to your hand.", "card_art_asset_id": "asset_spell_scroll_of_arcane_reclamation"},
        {"spell_id": "spl_29", "name": "Scroll of Monument Restoration", "axie_class_affinity": "neutral", "mana_cost": 1, "spell_type": "INSTANT", "effect_type": "RETURN_HAND", "base_value": 1, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Return a Structure card from discard pile to your hand.", "card_art_asset_id": "asset_spell_scroll_of_monument_restoration"},
        {"spell_id": "spl_30", "name": "Venomous Distortion", "axie_class_affinity": "reptile", "mana_cost": 2, "spell_type": "TARGETED", "effect_type": "SWAP_STATS", "base_value": 0, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Choose an opponent creature and swap its Attack and Defense values.", "card_art_asset_id": "asset_spell_venomous_distortion"},
        {"spell_id": "spl_31", "name": "Serpent Eye Ring", "axie_class_affinity": "reptile", "mana_cost": 2, "spell_type": "INSTANT", "effect_type": "DRAW", "base_value": 1, "scaling_formula": "COUNT_SCALED", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Draw 1 card for each of your empty lanes.", "card_art_asset_id": "asset_spell_serpent_eye_ring"},
        {"spell_id": "spl_32", "name": "Bug Swarm Incense", "axie_class_affinity": "bug", "mana_cost": 3, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "LANE", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Target lane blocked from summoning next round.", "card_art_asset_id": "asset_spell_bug_swarm_incense"},
        {"spell_id": "spl_33", "name": "Sprout Growth", "axie_class_affinity": "plant", "mana_cost": 1, "spell_type": "INSTANT", "effect_type": "DRAW", "base_value": 2, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Draw 2 cards from your deck.", "card_art_asset_id": "asset_spell_sprout_growth"},
        {"spell_id": "spl_34", "name": "Subjugating Roar", "axie_class_affinity": "beast", "mana_cost": 3, "spell_type": "GLOBAL", "effect_type": "DESTROY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "ALL_CREATURES", "cast_window": "ACTION_PHASE", "rarity": "EPIC", "description": "Destroy all enemy creatures with Rarity 3 or lower.", "card_art_asset_id": "asset_spell_subjugating_roar"},
        {"spell_id": "spl_35", "name": "Heart of Oak", "axie_class_affinity": "plant", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose a Plant creature and attack opposing creature in its lane.", "card_art_asset_id": "asset_spell_heart_of_oak"},
        {"spell_id": "spl_36", "name": "Atias Harmony", "axie_class_affinity": "neutral", "mana_cost": 1, "spell_type": "INSTANT", "effect_type": "MANA_SURGE", "base_value": 2, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "All allied creature abilities cost 0 Energy this round.", "card_art_asset_id": "asset_spell_atias_harmony"},
        {"spell_id": "spl_37", "name": "Spatial Slip", "axie_class_affinity": "aquatic", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "RETURN_HAND", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose a creature and return it to your hand.", "card_art_asset_id": "asset_spell_spatial_slip"},
        {"spell_id": "spl_38", "name": "Dark Chrysalis", "axie_class_affinity": "bug", "mana_cost": 1, "spell_type": "INSTANT", "effect_type": "DESTROY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Destroy an allied creature to gain 4 Energy.", "card_art_asset_id": "asset_spell_dark_chrysalis"},
        {"spell_id": "spl_39", "name": "Bramble Dismantle", "axie_class_affinity": "bug", "mana_cost": 1, "spell_type": "INSTANT", "effect_type": "DESTROY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Destroy an allied structure to gain 4 Energy.", "card_art_asset_id": "asset_spell_bramble_dismantle"},
        {"spell_id": "spl_40", "name": "Sandstorm Scepter", "axie_class_affinity": "reptile", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose a Reptile creature and attack opposing creature in its lane.", "card_art_asset_id": "asset_spell_sandstorm_scepter"},
        {"spell_id": "spl_41", "name": "Lunacian Reposition", "axie_class_affinity": "neutral", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "UTILITY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "LANE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose one of your structures and move it to an empty lane.", "card_art_asset_id": "asset_spell_lunacian_reposition"},
        {"spell_id": "spl_42", "name": "Gale Wind Surge", "axie_class_affinity": "bird", "mana_cost": 3, "spell_type": "TARGETED", "effect_type": "RETURN_HAND", "base_value": 1, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Choose an opposing creature and return it to opponent hand.", "card_art_asset_id": "asset_spell_gale_wind_surge"},
        {"spell_id": "spl_43", "name": "Soul Resurrection", "axie_class_affinity": "reptile", "mana_cost": 2, "spell_type": "INSTANT", "effect_type": "RETURN_HAND", "base_value": 1, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Return a creature from discard pile to your hand.", "card_art_asset_id": "asset_spell_soul_resurrection"},
        {"spell_id": "spl_44", "name": "Cataclysmic Eruption", "axie_class_affinity": "reptile", "mana_cost": 4, "spell_type": "TARGETED", "effect_type": "DESTROY", "base_value": 1, "scaling_formula": "NONE", "target_scope": "LANE", "cast_window": "ACTION_PHASE", "rarity": "MYSTIC", "description": "Destroy all structures and creatures in target lane.", "card_art_asset_id": "asset_spell_cataclysmic_eruption"},
        {"spell_id": "spl_45", "name": "Affinity Conflux", "axie_class_affinity": "neutral", "mana_cost": 1, "spell_type": "INSTANT", "effect_type": "MANA_SURGE", "base_value": 2, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Gain 1 Energy for every distinct affinity on the field.", "card_art_asset_id": "asset_spell_affinity_conflux"},
        {"spell_id": "spl_46", "name": "Primal Overcharge", "axie_class_affinity": "beast", "mana_cost": 2, "spell_type": "INSTANT", "effect_type": "MANA_SURGE", "base_value": 2, "scaling_formula": "NONE", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Discard your hand and gain 4 Energy.", "card_art_asset_id": "asset_spell_primal_overcharge"},
        {"spell_id": "spl_47", "name": "Revenge of the Fallen", "axie_class_affinity": "beast", "mana_cost": 3, "spell_type": "TARGETED", "effect_type": "DAMAGE", "base_value": 5, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "RARE", "description": "Grant a creature bonus Attack equal to damage taken.", "card_art_asset_id": "asset_spell_revenge_of_the_fallen"},
        {"spell_id": "spl_48", "name": "Nectar of Life", "axie_class_affinity": "plant", "mana_cost": 1, "spell_type": "TARGETED", "effect_type": "HEAL", "base_value": 5, "scaling_formula": "NONE", "target_scope": "SINGLE_CREATURE", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Choose an allied creature and heal all its damage.", "card_art_asset_id": "asset_spell_nectar_of_life"},
        {"spell_id": "spl_49", "name": "Seed of Atia", "axie_class_affinity": "beast", "mana_cost": 1, "spell_type": "INSTANT", "effect_type": "MANA_SURGE", "base_value": 2, "scaling_formula": "COUNT_SCALED", "target_scope": "PLAYER", "cast_window": "ACTION_PHASE", "rarity": "COMMON", "description": "Gain 1 Energy for each of your creatures on the field.", "card_art_asset_id": "asset_spell_seed_of_atia"},
    ]

    assert len(spells) == 49, f"Expected 49 spells, found {len(spells)}"
    assert sum(s["mana_cost"] for s in spells) == 97, f"Sum of mana costs must be 97, got {sum(s['mana_cost'] for s in spells)}"

    fieldnames = [
        "spell_id", "name", "axie_class_affinity", "mana_cost", "spell_type",
        "effect_type", "base_value", "scaling_formula", "target_scope",
        "cast_window", "rarity", "description", "card_art_asset_id"
    ]

    with open(OUTPUT_SPELLS_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(spells)

    print(f"✓ Generated {OUTPUT_SPELLS_PATH} ({len(spells) + 1} lines)")


def main():
    print("====================================================")
    print("Lunacian Card Wars: Card Engine Master Dataset ETL")
    print("====================================================")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    compile_floops_matrix()
    compile_structures_master()
    compile_spells_master()
    print("====================================================")
    print("ETL COMPILATION COMPLETE — ALL 3 DATASETS GENERATED")
    print("====================================================")


if __name__ == "__main__":
    main()
