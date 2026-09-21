#!/usr/bin/env python3
# ===============================================================================
# [MODULE_NAME]: compile_card_master_datasets.py
# [SYSTEM]: lunacian_card_wars
# [DOMAIN]: Data / ETL Pipeline
# [INTENT]: Compiles raw on-chain demographic census and Adventure Time card data into normalized master game engine datasets for Axie Floops, Structures, and Spells.
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
    # Parse buildings from adventrue_time_cards.csv
    structures_raw = []
    with open(ADVENTURE_CARDS_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get("Card_type", "").strip().lower() == "building":
                structures_raw.append(row)

    assert len(structures_raw) == 30, f"Expected 30 buildings, found {len(structures_raw)}"

    # Canonical mapping for buildings
    structures_processed = []
    for idx, b in enumerate(structures_raw, start=1):
        name = b["Card"].strip()
        str_id = f"str_{idx:02d}"
        
        # Determine landscape based on name and keywords
        name_lower = name.lower()
        if any(k in name_lower for k in ["corn", "silo", "hen house"]):
            landscape = "corn_fields"
        elif any(k in name_lower for k in ["solitude", "comfy", "cardboard", "windmill", "stonehenge"]):
            landscape = "blue_plains"
        elif any(k in name_lower for k in ["candy", "fruit", "nicelands", "puffy", "school"]):
            landscape = "nice_lands"
        elif any(k in name_lower for k in ["sand", "pyramid", "sphinx", "sun"]):
            landscape = "sandy_lands"
        elif any(k in name_lower for k in ["funeral", "ghost", "mausoleum", "obelisx", "palace of bone", "spirit", "autoplucker"]):
            landscape = "useless_swamp"
        else:
            landscape = "rainbow"

        # Determine mana cost & HP
        cost_raw = b.get("mana cost", "").strip()
        mana_cost = int(cost_raw) if cost_raw.isdigit() else 2
        
        def_raw = b.get("DEF", "").strip()
        base_hp = int(def_raw) if def_raw.isdigit() else 15

        desc = b.get("Floop ability", "").strip()

        # Determine passive effect type, value, trigger, target
        if "Defense" in desc or "defense" in desc:
            passive_type = "BUFF_DEF"
            val = 4
        elif "Attack" in desc or "attack" in desc:
            passive_type = "BUFF_ATK"
            val = 3
        elif "Damage" in desc or "damage" in desc:
            passive_type = "DAMAGE_TRIGGER"
            val = 5
        elif "heal" in desc.lower():
            passive_type = "HEAL_TRIGGER"
            val = 5
        elif "swap" in desc.lower():
            passive_type = "SWAP_STATS"
            val = 0
        else:
            passive_type = "UTILITY"
            val = 1

        trigger = "PASSIVE"
        if "destroyed" in desc.lower():
            trigger = "ON_DESTROY"
        elif "placed" in desc.lower():
            trigger = "ON_SUMMON"
        elif "start of turn" in desc.lower():
            trigger = "START_OF_TURN"
        elif "floop ability" in desc.lower():
            trigger = "ON_FLOOP"

        target_scope = "LANE_UNIT"
        if "hero" in desc.lower():
            target_scope = "HERO"

        scaling = "NONE"
        if "for each" in desc.lower() or "for every" in desc.lower():
            scaling = "SCALING_COUNT"

        art_id = f"art_str_{name.lower().replace(' ', '_').replace(\"'\", '')}"

        structures_processed.append({
            "structure_id": str_id,
            "name": name,
            "landscape": landscape,
            "mana_cost": mana_cost,
            "base_hp": base_hp,
            "passive_effect_type": passive_type,
            "effect_value": val,
            "scaling_formula": scaling,
            "activation_trigger": trigger,
            "target_scope": target_scope,
            "lore_description": desc,
            "card_art_asset_id": art_id
        })

    fieldnames = [
        "structure_id", "name", "landscape", "mana_cost", "base_hp",
        "passive_effect_type", "effect_value", "scaling_formula",
        "activation_trigger", "target_scope", "lore_description", "card_art_asset_id"
    ]

    with open(OUTPUT_STRUCTURES_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(structures_processed)

    print(f"✓ Generated {OUTPUT_STRUCTURES_PATH} ({len(structures_processed) + 1} lines)")


def compile_spells_master():
    """Generates spells_master.csv (49 data rows + 1 header = 50 lines)."""
    spells_raw = []
    with open(ADVENTURE_CARDS_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get("Card_type", "").strip().lower() == "spell":
                spells_raw.append(row)

    assert len(spells_raw) == 49, f"Expected 49 spells, found {len(spells_raw)}"

    spells_processed = []
    for idx, s in enumerate(spells_raw, start=1):
        name = s["Card"].strip()
        spell_id = f"spl_{idx:02d}"

        # Determine affinity from text/name
        name_lower = name.lower()
        desc = s.get("Floop ability", "").strip()
        desc_lower = desc.lower()

        if "corn" in name_lower or "corn" in desc_lower:
            affinity = "corn_fields"
        elif "blue plains" in desc_lower or "puma" in name_lower or "teleport" in name_lower:
            affinity = "blue_plains"
        elif "nicelands" in desc_lower or "hug" in name_lower or "pie" in name_lower or "butt" in name_lower:
            affinity = "nice_lands"
        elif "sandy" in desc_lower or "volcano" in name_lower or "ankhs" in name_lower:
            affinity = "sandy_lands"
        elif "useless swamp" in desc_lower or "bone" in name_lower or "doom" in name_lower or "gloom" in name_lower or "torch" in name_lower:
            affinity = "useless_swamp"
        else:
            affinity = "universal"

        cost_raw = s.get("mana cost", "").strip()
        mana_cost = int(cost_raw) if cost_raw.isdigit() else 2

        # Spell type & Effect type
        if "destroy" in desc_lower:
            effect_type = "DESTROY"
            base_val = 1
        elif "damage" in desc_lower:
            effect_type = "DAMAGE"
            base_val = 5
        elif "heal" in desc_lower:
            effect_type = "HEAL"
            base_val = 5
        elif "draw" in desc_lower:
            effect_type = "DRAW"
            base_val = 2
        elif "magic point" in desc_lower:
            effect_type = "MANA_SURGE"
            base_val = 2
        elif "return" in desc_lower:
            effect_type = "RETURN_HAND"
            base_val = 1
        elif "switch" in desc_lower or "swap" in desc_lower:
            effect_type = "SWAP_STATS"
            base_val = 0
        else:
            effect_type = "UTILITY"
            base_val = 1

        spell_type = "TARGETED"
        if "all" in desc_lower or "field" in desc_lower:
            spell_type = "GLOBAL"
        elif "draw" in desc_lower or "shuffle" in desc_lower or "magic point" in desc_lower:
            spell_type = "INSTANT"

        target_scope = "SINGLE_CREATURE"
        if "hero" in desc_lower or "leader" in desc_lower:
            target_scope = "HERO"
        elif "all" in desc_lower:
            target_scope = "ALL_CREATURES"
        elif "lane" in desc_lower:
            target_scope = "LANE"
        elif "player" in desc_lower or "hand" in desc_lower:
            target_scope = "PLAYER"

        turn_duration = 1 if "next turn" in desc_lower or "this turn" in desc_lower else 0
        scaling_rule = "NONE"
        if "for each" in desc_lower or "for every" in desc_lower:
            scaling_rule = "COUNT_SCALED"

        art_id = f"art_spl_{name.lower().replace(' ', '_').replace(\"'\", '')}"

        spells_processed.append({
            "spell_id": spell_id,
            "name": name,
            "landscape_affinity": affinity,
            "mana_cost": mana_cost,
            "spell_type": spell_type,
            "effect_type": effect_type,
            "base_value": base_val,
            "scaling_rule": scaling_rule,
            "target_scope": target_scope,
            "turn_duration": turn_duration,
            "lore_description": desc,
            "card_art_asset_id": art_id
        })

    fieldnames = [
        "spell_id", "name", "landscape_affinity", "mana_cost", "spell_type",
        "effect_type", "base_value", "scaling_rule", "target_scope",
        "turn_duration", "lore_description", "card_art_asset_id"
    ]

    with open(OUTPUT_SPELLS_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(spells_processed)

    print(f"✓ Generated {OUTPUT_SPELLS_PATH} ({len(spells_processed) + 1} lines)")


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
